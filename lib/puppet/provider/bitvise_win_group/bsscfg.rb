#
# TODO documentation
# TODO remove restart_service and handle as a puppet resource
# TODO figure out approach for exists, create, destroy
# TODO remove trusted_lsp_only since it was only for testing
# TODO add groups
# TODO handle fg = WIN32OLE.new('Bitvise.BssCfg') accross multiple versions, how do we query for version?
# TODO do we create a WIN32OLE.new() for each method? Can this be global? Need to find examples of best practice
# * create re-usable code for load, lock, set, save, unlock
# TODO if we continue to use eval make sure strings are appropriately contained
# TODO stop on error
#
Puppet::Type.type(:bitvise_win_group).provide(:bsscfg) do
  desc 'This provider manages bitvise windows groups'

  defaultfor kernel: :windows
  confine    kernel: :windows

  require 'win32ole'

  #
  # Conversion helper functions
  #

  # If we put in a boolean we get out an integer
  # If we get in an integer we get out a boolean
  def bool_int_convert(val)
    Puppet.debug("bool_int_convert with val = #{val} and [true, false].include? val #{[true, false].include? val}")
    values = {
      :false => 0,
      :true  => 1
    }
    r = [:true, :false].include?(val) ? values[val] : values.invert[val]
    Puppet.debug("bool_int_convert with r = #{r}")
    r
  end

  def shell_access_type_convert(val)
    Puppet.debug("shell_access_type_convert with val = #{val} and val_is_a?(Integer) #{val.is_a?(Integer)} and val_is_a?(Symbol) #{val.is_a?(Symbol)}")
    values = {
      'default'    => 1,
      'none'       => 2,
      'BvShell'    => 10,
      'cmd'        => 3,
      'PowerShell' => 4,
      'Bash'       => 5,
      'Git'        => 6,
      'Telnet'     => 9,
      'Custom'     => 7
    }
    r = val.is_a?(Integer) ? values.invert[val] : values[val.to_s]
    Puppet.debug("shell_access_type_convert with r = #{r}")
    r
  end

  def group_type_convert(val)
    Puppet.debug("group_type_convert with val = #{val} and val_is_a?(Integer) #{val.is_a?(Integer)} and val_is_a?(Symbol) #{val.is_a?(Symbol)}")
    values = {
      'everyone' => 0,
      'local'    => 1,
      'domain'   => 2
    }
    r = val.is_a?(Integer) ? values.invert[val] : values[val.to_s]
    Puppet.debug("group_type_convert with r = #{r}")
    r
  end

  def logon_type_convert(val)
    Puppet.debug("logon_type_convert with val = #{val} and val_is_a?(Integer) #{val.is_a?(Integer)} and val_is_a?(Symbol) #{val.is_a?(Symbol)}")
    values = {
      'interactive' => 1,
      'network'     => 2,
      'bash'        => 3
    }
    r = val.is_a?(Integer) ? values.invert[val] : values[val.to_s]
    Puppet.debug("logon_type_convert with r = #{r}")
    r
  end

  def account_failure_convert(val)
    Puppet.debug("account_failure_convert with val = #{val} and val_is_a?(Integer) #{val.is_a?(Integer)} and val_is_a?(Symbol) #{val.is_a?(Symbol)}")
    values = {
      'deny login'       => 1,
      'restrict access'  => 2,
      'disable profile'  => 3,
       'no restrictions' => 4
    }
    r = val.is_a?(Integer) ? values.invert[val] : values[val.to_s]
    Puppet.debug("account_failure_convert with r = #{r}")
    r
  end

  def display_time_convert(val)
    Puppet.debug("display_time_convert with val = #{val} and val_is_a?(Integer) #{val.is_a?(Integer)} and val_is_a?(Symbol) #{val.is_a?(Symbol)}")
    values = {
      'local with offset' => 1,
      'local'             => 2,
      'UTC'               => 3
    }
    r = val.is_a?(Integer) ? values.invert[val] : values[val.to_s]
    Puppet.debug("display_time_convert with r = #{r}")
    r
  end

  def restart_service
    Puppet.debug('restarting service')
    `net stop BvSshServer`
    `net start BvSshServer`
    Puppet.debug('restarted service')
  end

  #
  # Type and Provider methods
  #

  def exists?
    Puppet.debug('entering exists?')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          return true
        end
      end
    else # Virtual group
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          return true
        end
      end
    end
    false
  end

  def login_allowed
    Puppet.debug('entering login_allowed getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.loginAllowed
        end
      end
    else # Virtual group
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.loginAllowed
        end
      end
    end
    Puppet.debug("value of login_allowed found is #{val}, value converted to be returned is #{bool_int_convert(val)}")
    bool_int_convert(val)
  end

  def login_allowed=(value)
    Puppet.debug("entering login_allowed=value with name: #{resource[:group_name]} and login_allowed #{resource[:login_allowed]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting loginAllowed to #{bool_int_convert(value)}")
          entry.loginAllowed = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting loginAllowed to #{bool_int_convert(value)}")
          entry.loginAllowed = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def shell_access_type
    Puppet.debug('entering shell_access_type getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.term.shellAccessType
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.term.shellAccessType
        end
      end
    end
    Puppet.debug("value of shell_access_type is #{val} and converted to be returned is #{shell_access_type_convert(val)}")
    shell_access_type_convert(val)
  end

  def shell_access_type=(value)
    Puppet.debug("entering shell_access_type=value with group_name: #{resource[:group_name]} and shell_access_type #{resource[:shell_access_type]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting shellAccessType to #{shell_access_type_convert(value)}")
          entry.term.shellAccessType = shell_access_type_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting shellAccessType to #{shell_access_type_convert(value)}")
          entry.term.shellAccessType = shell_access_type_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def logon_type
    Puppet.debug('entering logon_type getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.session.logonType
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.session.logonType
        end
      end
    end
    Puppet.debug("value of logon_type is #{val} and converted to be returned is #{logon_type_convert(val)}")
    logon_type_convert(val)
  end

  def logon_type=(value)
    Puppet.debug("entering logon_type=value with group_name: #{resource[:group_name]} and logon_type #{resource[:logon_type]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting logonType to #{logon_type_convert(value)}")
          entry.session.logonType = logon_type_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting logonType to #{logon_type_convert(value)}")
          entry.session.logonType = logon_type_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def on_account_info_failure
    Puppet.debug('entering on_account_info_failure getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.session.onAccountInfoFailure
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.session.onAccountInfoFailure
        end
      end
    end
    Puppet.debug("value of on_account_info_failure is #{val} and converted to be returned is #{account_failure_convert(val)}")
    account_failure_convert(val)
  end

  def on_account_info_failure=(value)
    Puppet.debug("entering on_account_info_failure=value with group_name: #{resource[:group_name]} and on_account_info_failure #{resource[:on_account_info_failure]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting onAccountInfoFailure to #{account_failure_convert(value)}")
          entry.session.onAccountInfoFailure = account_failure_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting onAccountInfoFailure to #{account_failure_convert(value)}")
          entry.session.onAccountInfoFailure = account_failure_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def max_wait_time
    Puppet.debug('entering max_wait_time getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.session.windowsOnLogonCmd.maxWaitTime
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.session.windowsOnLogonCmd.maxWaitTime
        end
      end
    end
    Puppet.debug("value of max_wait_time is #{val} and converted to be returned is #{val}")
    val
  end

  def max_wait_time=(value)
    Puppet.debug("entering max_wait_time=value with group_name: #{resource[:group_name]} and max_wait_time #{resource[:max_wait_time]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting maxWaitTime to #{value}")
          entry.session.windowsOnLogonCmd.maxWaitTime = value
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting maxWaitTime to #{value}")
          entry.session.windowsOnLogonCmd.maxWaitTime = value
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def permit_init_dir_fallback
    Puppet.debug("entering permit_init_dir_fallback getter with group_name: #{resource[:group_name]} and value #{resource[:permit_init_dir_fallback]}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.term.permitInitDirFallback
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.term.permitInitDirFallback
        end
      end
    end
    Puppet.debug("value of permit_init_dir_fallback is #{val} and converted to be returned is #{bool_int_convert(val)} and [true, false].include? val #{[true, false].include? bool_int_convert(val)}")
    bool_int_convert(val)
  end

  def permit_init_dir_fallback=(value)
    Puppet.debug("entering permit_init_dir_fallback=value with group_name: #{resource[:group_name]} and permit_init_dir_fallback #{resource[:permit_init_dir_fallback]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting permitInitDirFallback to #{bool_int_convert(value)}")
          entry.term.permitInitDirFallback = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting permitInitDirFallback to #{bool_int_convert(value)}")
          entry.term.permitInitDirFallback = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def allow_agent_fwd_cygwin
    Puppet.debug("entering allow_agent_fwd_cygwin getter with group_name: #{resource[:group_name]} and value #{resource[:allow_agent_fwd_cygwin]}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.term.allowAgentFwdCygwin
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.term.allowAgentFwdCygwin
        end
      end
    end
    Puppet.debug("value of allow_agent_fwd_cygwin is #{val} and converted to be returned is #{bool_int_convert(val)} and [true, false].include? val #{[true, false].include? bool_int_convert(val)}")
    bool_int_convert(val)
  end

  def allow_agent_fwd_cygwin=(value)
    Puppet.debug("entering allow_agent_fwd_cygwin=value with group_name: #{resource[:group_name]} and allow_agent_fwd_cygwin #{resource[:allow_agent_fwd_cygwin]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting allowAgentFwdCygwin to #{bool_int_convert(value)}")
          entry.term.allowAgentFwdCygwin = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting allowAgentFwdCygwin to #{bool_int_convert(value)}")
          entry.term.allowAgentFwdCygwin = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def allow_agent_fqd_putty
    Puppet.debug("entering allow_agent_fqd_putty getter with group_name: #{resource[:group_name]} and value #{resource[:allow_agent_fqd_putty]}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.term.allowAgentFwdPutty
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.term.allowAgentFwdPutty
        end
      end
    end
    Puppet.debug("value of allow_agent_fqd_putty is #{val} and converted to be returned is #{bool_int_convert(val)} and [true, false].include? val #{[true, false].include? bool_int_convert(val)}")
    bool_int_convert(val)
  end

  def allow_agent_fqd_putty=(value)
    Puppet.debug("entering allow_agent_fqd_putty=value with group_name: #{resource[:group_name]} and allow_agent_fqd_putty #{resource[:allow_agent_fqd_putty]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting allowAgentFwdPutty to #{bool_int_convert(value)}")
          entry.term.allowAgentFwdPutty = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting allowAgentFwdPutty to #{bool_int_convert(value)}")
          entry.term.allowAgentFwdPutty = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def load_profile_for_file_xfer
    Puppet.debug("entering load_profile_for_file_xfer getter with group_name: #{resource[:group_name]} and value #{resource[:load_profile_for_file_xfer]}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.xfer.loadProfileForFileXfer
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.xfer.loadProfileForFileXfer
        end
      end
    end
    Puppet.debug("value of load_profile_for_file_xfer is #{val} and converted to be returned is #{bool_int_convert(val)} and [true, false].include? val #{[true,
                                                                                                                                                           false].include? bool_int_convert(val)}")
    bool_int_convert(val)
  end

  def load_profile_for_file_xfer=(value)
    Puppet.debug("entering load_profile_for_file_xfer=value with group_name: #{resource[:group_name]} and load_profile_for_file_xfer #{resource[:load_profile_for_file_xfer]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting loadProfileForFileXfer to #{bool_int_convert(value)}")
          entry.xfer.loadProfileForFileXfer = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting loadProfileForFileXfer to #{bool_int_convert(value)}")
          entry.xfer.loadProfileForFileXfer = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def display_time
    Puppet.debug("entering display_time getter with group_name: #{resource[:group_name]} and value #{resource[:display_time]}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.xfer.displayTime
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.xfer.displayTime
        end
      end
    end
    Puppet.debug("value of display_time is #{val} and converted to be returned is #{display_time_convert(val)} and [true, false].include? val #{[true, false].include? bool_int_convert(val)}")
    display_time_convert(val)
  end

  def display_time=(value)
    Puppet.debug("entering display_time=value with group_name: #{resource[:group_name]} and display_time #{resource[:display_time]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting displayTime to #{display_time_convert(value)}")
          entry.xfer.displayTime = display_time_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting displayTime to #{display_time_convert(value)}")
          entry.xfer.displayTime = display_time_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def sfs_home_dir
    Puppet.debug("entering sfs_home_dir getter with group_name: #{resource[:group_name]} and value #{resource[:sfs_home_dir]}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.xfer.sfsHomeDir
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = entry.xfer.sfsHomeDir
        end
      end
    end
    Puppet.debug("value of sfs_home_dir is #{val}}")
    val
  end

  def sfs_home_dir=(value)
    Puppet.debug("entering sfs_home_dir=value with group_name: #{resource[:group_name]} and sfs_home_dir #{resource[:sfs_home_dir]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting sfsHomeDir to #{value}")
          entry.xfer.sfsHomeDir = value
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          Puppet.debug("setting sfsHomeDir to #{value}")
          entry.xfer.sfsHomeDir = value
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  #   def mounts
  #     Puppet.debug("entering mounts getter with group_name: #{resource[:group_name]} and value #{resource[:mounts]}")
  #     cfg = WIN32OLE.new('Bitvise.BssCfg')
  #     cfg.settings.load
  #     val = nil
  #     if resource[:type] == 'windows'
  #       cfg.settings.access.winGroups.entries.each do |entry|
  #         if entry.group == resource[:group_name]
  #           val = entry.xfer.sfsHomeDir
  #         end
  #       end
  #     else
  #       cfg.settings.access.virtGroups.entries.each do |entry|
  #         if entry.group == resource[:group_name]
  #           val = entry.xfer.sfsHomeDir
  #         end
  #       end
  #     end
  #     Puppet.debug("value of mounts is #{val}}")
  #     val
  #   end

  #   def mounts=(value)
  #     Puppet.debug("entering mounts=value with group_name: #{resource[:group_name]} and mounts #{resource[:mounts]} and value #{value}")
  #     cfg = WIN32OLE.new('Bitvise.BssCfg')
  #     cfg.settings.load
  #     cfg.settings.lock
  #     if resource[:type] == 'windows'
  #       cfg.settings.access.winGroups.entries.each do |entry|
  #         if entry.group == resource[:group_name]
  #           Puppet.debug("setting sfsHomeDir to #{value}")
  #           entry.xfer.sfsHomeDir = value
  #         end
  #       end
  #     else
  #       cfg.settings.access.virtGroups.entries.each do |entry|
  #         if entry.group == resource[:group_name]
  #           Puppet.debug("setting sfsHomeDir to #{value}")
  #           entry.xfer.sfsHomeDir = value
  #         end
  #       end
  #     end
  #     cfg.settings.save
  #     cfg.settings.unlock
  #     restart_service
  #   end

  def create
    Puppet.debug('entering create')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.new.groupType = group_type_convert(resource[:group_type]) # $cfg.enums.GroupType.local
      cfg.settings.access.winGroups.new.group = resource[:group_name]
      cfg.settings.access.winGroups.new.winDomain = resource[:domain] unless resource[:domain].nil?
      cfg.settings.access.winGroups.new.loginAllowed = bool_int_convert(resource[:login_allowed])
      cfg.settings.access.winGroups.new.term.shellAccessType = shell_access_type_convert(resource[:shell_access_type])
      cfg.settings.access.winGroups.new.session.logonType = logon_type_convert(resource[:logon_type])
      cfg.settings.access.winGroups.new.session.onAccountInfoFailure = account_failure_convert(resource[:on_account_info_failure])
      cfg.settings.access.winGroups.new.session.windowsOnLogonCmd.maxWaitTime = resource[:max_wait_time]
      cfg.settings.access.winGroups.new.term.permitInitDirFallback = bool_int_convert(resource[:permit_init_dir_fallback])
      cfg.settings.access.winGroups.new.term.allowAgentFwdCygwin = bool_int_convert(resource[:allow_agent_fwd_cygwin])
      cfg.settings.access.winGroups.new.term.allowAgentFwdPutty = bool_int_convert(resource[:allow_agent_fqd_putty])
      cfg.settings.access.winGroups.new.xfer.loadProfileForFileXfer = bool_int_convert(resource[:load_profile_for_file_xfer])
      cfg.settings.access.winGroups.new.xfer.displayTime = display_time_convert(resource[:display_time])
      # Mount points
      cfg.settings.access.winGroups.new.xfer.mountPoints.Clear()
      resource[:mounts].each do |mount|
        cfg.settings.access.winGroups.new.xfer.mountPoints.new.SetDefaults()
        cfg.settings.access.winGroups.new.xfer.mountPoints.new.sfsMountPath = mount['sfs_mount_path'] unless mount['sfs_mount_path'].nil?
        cfg.settings.access.winGroups.new.xfer.mountPoints.new.allowUnlimitedAccess = mount['allow_unlimited_access'] unless mount['allow_unlimited_access'].nil?
        cfg.settings.access.winGroups.new.xfer.mountPoints.new.realRootPath = mount['real_root_path'] unless mount['real_root_path'].nil?
        cfg.settings.access.winGroups.new.xfer.mountPoints.new.fileSharingBeh = mount['file_sharing_behavior'] unless mount['file_sharing_behavior'].nil?
        cfg.settings.access.winGroups.new.xfer.mountPoints.new.fileSharingDl = mount['file_sharing_dl'] unless mount['file_sharing_dl'].nil?
        cfg.settings.access.winGroups.new.xfer.mountPoints.NewCommit()
      end
      cfg.settings.access.winGroups.new.xfer.sfsHomeDir = resource[:sfs_home_dir]
      # Listen rules
      cfg.settings.access.winGroups.new.fwding.SetDefaults()
      Puppet.debug('clearing listenin rules')
      cfg.settings.access.winGroups.new.fwding.listenRules.Clear()
      resource[:listen_rules].each do |rule|
        Puppet.debug('enter listen rules loop and set defaults')
        cfg.settings.access.winGroups.new.fwding.listenRules.new.SetDefaults()
        cfg.settings.access.winGroups.new.fwding.listenRules.new.intfRule.SetDefaults()
        cfg.settings.access.winGroups.new.fwding.listenRules.new.portRangeRule.portFrom = rule['port_from'] unless rule['port_from'].nil?
        cfg.settings.access.winGroups.new.fwding.listenRules.new.intfRule.intfType = rule['intf_type'] unless rule['intf_type'].nil?
        cfg.settings.access.winGroups.new.fwding.listenRules.new.intfRule.ipv4range = rule['ipv4_range'] unless rule['ipv4_range'].nil?
        cfg.settings.access.winGroups.new.fwding.listenRules.new.intfRule.ipv4end = rule['ipv4_end'] unless rule['ipv4_end'].nil?
        cfg.settings.access.winGroups.new.fwding.listenRules.new.intfRule.ipv6range = rule['ipv6_range'] unless rule['ipv6_range'].nil?
        cfg.settings.access.winGroups.new.fwding.listenRules.new.intfRule.ipv6end = rule['ipv6_end'] unless rule['ipv6_end'].nil?
        cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.SetDefaults()
        cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.overrideListenInterface = rule['override_listen_interface'] unless rule['override_listen_interface'].nil?
        Puppet.debug('clear acceptrules')
        cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.Clear() unless rule['accept_rules'].empty?
        rule['accept_rules'].each do |r|
          Puppet.debug('enter accept rules loop and set defaults')
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.new.SetDefaults()
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.SetDefaults()
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.addressType = r['address_type'] unless r['address_type'].nil?
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.ipv4range = r['ipv4_range'] unless r['ipv4_range'].nil?
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.ipv4end = r['ipv4_end'] unless r['ipv4_end'].nil?
          Puppet.debug('try to commit the accept rule')
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.NewCommit()
        end
        Puppet.debug('exit accept rules loop and commit the listen rule')
        cfg.settings.access.winGroups.new.fwding.listenRules.NewCommit()
      end
      Puppet.debug('commit the wingroup')
      cfg.settings.access.winGroups.NewCommit()
    else # Virtual group
      # cfg.settings.access.virtGroups.new.groupType = 1 # $cfg.enums.GroupType.local
      cfg.settings.access.virtGroups.new.group = resource[:group_name]
      cfg.settings.access.virtGroups.new.loginAllowed = bool_int_convert(resource[:login_allowed])
      cfg.settings.access.virtGroups.new.term.shellAccessType = shell_access_type_convert(resource[:shell_access_type])
      cfg.settings.access.virtGroups.new.session.logonType = logon_type_convert(resource[:logon_type])
      cfg.settings.access.virtGroups.new.session.onAccountInfoFailure = account_failure_convert(resource[:on_account_info_failure])
      cfg.settings.access.virtGroups.new.session.windowsOnLogonCmd.maxWaitTime = resource[:max_wait_time]
      cfg.settings.access.virtGroups.new.term.permitInitDirFallback = bool_int_convert(resource[:permit_init_dir_fallback])
      cfg.settings.access.virtGroups.new.term.allowAgentFwdCygwin = bool_int_convert(resource[:allow_agent_fwd_cygwin])
      cfg.settings.access.virtGroups.new.term.allowAgentFwdPutty = bool_int_convert(resource[:allow_agent_fqd_putty])
      cfg.settings.access.virtGroups.new.xfer.loadProfileForFileXfer = bool_int_convert(resource[:load_profile_for_file_xfer])
      cfg.settings.access.virtGroups.new.xfer.displayTime = display_time_convert(resource[:display_time])
      # Mount points
      cfg.settings.access.virtGroups.new.xfer.mountPoints.Clear()
      resource[:mounts].each do |mount|
        cfg.settings.access.virtGroups.new.xfer.mountPoints.new.SetDefaults()
        cfg.settings.access.virtGroups.new.xfer.mountPoints.new.sfsMountPath = mount['sfs_mount_path'] unless mount['sfs_mount_path'].nil?
        cfg.settings.access.virtGroups.new.xfer.mountPoints.new.allowUnlimitedAccess = mount['allow_unlimited_access'] unless mount['allow_unlimited_access'].nil?
        cfg.settings.access.virtGroups.new.xfer.mountPoints.new.realRootPath = mount['real_root_path'] unless mount['real_root_path'].nil?
        cfg.settings.access.virtGroups.new.xfer.mountPoints.new.fileSharingBeh = mount['file_sharing_behavior'] unless mount['file_sharing_behavior'].nil?
        cfg.settings.access.virtGroups.new.xfer.mountPoints.new.fileSharingDl = mount['file_sharing_dl'] unless mount['file_sharing_dl'].nil?
        cfg.settings.access.virtGroups.new.xfer.mountPoints.NewCommit()
      end
      cfg.settings.access.virtGroups.new.xfer.sfsHomeDir = resource[:sfs_home_dir]
      # Listen rules
      cfg.settings.access.virtGroups.new.fwding.SetDefaults()
      cfg.settings.access.virtGroups.new.fwding.listenRules.Clear()
      resource[:listen_rules].each do |rule|
        cfg.settings.access.virtGroups.new.fwding.listenRules.new.SetDefaults()
        cfg.settings.access.virtGroups.new.fwding.listenRules.new.intfRule.SetDefaults()
        cfg.settings.access.virtGroups.new.fwding.listenRules.new.portRangeRule.portFrom = rule['port_from'] unless rule['port_from'].nil?
        cfg.settings.access.virtGroups.new.fwding.listenRules.new.intfRule.intfType = rule['intf_type'] unless rule['intf_type'].nil?
        cfg.settings.access.virtGroups.new.fwding.listenRules.new.intfRule.ipv4range = rule['ipv4_range'] unless rule['ipv4_range'].nil?
        cfg.settings.access.virtGroups.new.fwding.listenRules.new.intfRule.ipv4end = rule['ipv4_end'] unless rule['ipv4_end'].nil?
        cfg.settings.access.virtGroups.new.fwding.listenRules.new.intfRule.ipv6range = rule['ipv6_range'] unless rule['ipv6_range'].nil?
        cfg.settings.access.virtGroups.new.fwding.listenRules.new.intfRule.ipv6end = rule['ipv6_end'] unless rule['ipv6_end'].nil?
        cfg.settings.access.virtGroups.new.fwding.listenRules.new.instr.SetDefaults()
        cfg.settings.access.virtGroups.new.fwding.listenRules.new.instr.overrideListenInterface = rule['override_listen_interface'] unless rule['override_listen_interface'].nil?
        cfg.settings.access.virtGroups.new.fwding.listenRules.new.instr.acceptRules.Clear() unless rule['accept_rules'].empty?
        rule['accept_rules'].each do |r|
          cfg.settings.access.virtGroups.new.fwding.listenRules.new.instr.acceptRules.new.SetDefaults()
          cfg.settings.access.virtGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.SetDefaults()
          cfg.settings.access.virtGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.addressType = r['address_type'] unless r['address_type'].nil?
          cfg.settings.access.virtGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.ipv4range = r['ipv4_range'] unless r['ipv4_range'].nil?
          cfg.settings.access.virtGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.ipv4end = r['ipv4_end'] unless r['ipv4_end'].nil?
          cfg.settings.access.virtGroups.new.fwding.listenRules.new.instr.acceptRules.NewCommit()
        end
        cfg.settings.access.virtGroups.new.fwding.listenRules.NewCommit()
      end
      cfg.settings.access.virtGroups.NewCommit()
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def destroy
    Puppet.debug('entering destroy')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    i = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each_with_index do |entry, index|
        if entry.group == resource[:group_name]
          i = index
        end
      end
      cfg.settings.access.winGroups.Erase(i) unless i.nil?
    else
      cfg.settings.access.virtGroups.entries.each_with_index do |entry, index|
        if entry.group == resource[:group_name]
          i = index
        end
      end
      cfg.settings.access.virtGroups.Erase(i) unless i.nil?
    end
    cfg.settings.save
    cfg.settings.unlock
  end
end
