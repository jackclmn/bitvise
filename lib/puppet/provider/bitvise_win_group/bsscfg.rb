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
        false => 0,
        true  => 1
    }
    r = [true, false].include?(val) ? values[val] : values.invert()[val]
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
    r = val.is_a?(Integer) ? values.invert()[val] : values[val.to_s]
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
    r = val.is_a?(Integer) ? values.invert()[val] : values[val.to_s]
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
    r = val.is_a?(Integer) ? values.invert()[val] : values[val.to_s]
    Puppet.debug("logon_type_convert with r = #{r}")
    r
  end

  def account_failure_convert(val)
    Puppet.debug("account_failure_convert with val = #{val} and val_is_a?(Integer) #{val.is_a?(Integer)} and val_is_a?(Symbol) #{val.is_a?(Symbol)}")
    values = {
        'deny login'      => 1,
        'restrict access' => 2,
        'disable profile' => 3,
        'no restrictions' => 4
    }
    r = val.is_a?(Integer) ? values.invert()[val] : values[val.to_s]
    Puppet.debug("account_failure_convert with r = #{r}")
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
      cfg.settings.access.winGroups.NewCommit()
    else # Virtual group
      #cfg.settings.access.virtGroups.new.groupType = 1 # $cfg.enums.GroupType.local
      cfg.settings.access.virtGroups.new.group = resource[:group_name]
      cfg.settings.access.virtGroups.new.loginAllowed = bool_int_convert(resource[:login_allowed])
      cfg.settings.access.virtGroups.new.term.shellAccessType = shell_access_type_convert(resource[:shell_access_type])
      cfg.settings.access.virtGroups.new.session.logonType = logon_type_convert(resource[:logon_type])
      cfg.settings.access.winGroups.new.session.onAccountInfoFailure = account_failure_convert(resource[:on_account_info_failure])
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
