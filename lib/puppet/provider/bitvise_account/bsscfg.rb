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
Puppet::Type.type(:bitvise_account).provide(:bsscfg) do
  desc 'This provider manages bitvise accounts'

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
    r = [true, false].include?(val) ? values[val] : values.invert[val]
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
      'no restrictions'  => 4
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

  def security_context_convert(val)
    Puppet.debug("security_context_convert with val = #{val} and val_is_a?(Integer) #{val.is_a?(Integer)} and val_is_a?(Symbol) #{val.is_a?(Symbol)}")
    values = {
      'default'   => 0,
      'auto'      => 1,
      'local'     => 2,
      'domain'    => 3,
      'service'   => 4,
      'microsoft' => 5
    }
    r = val.is_a?(Integer) ? values.invert[val] : values[val.to_s]
    Puppet.debug("security_context_convert with r = #{r}")
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
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          return true
        end
      end
    else # Virtual account
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
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
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          val = entry.loginAllowed
        end
      end
    else # Virtual account
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          val = entry.loginAllowed
        end
      end
    end
    Puppet.debug("value of login_allowed found is #{val}, value converted to be returned is #{bool_int_convert(val)}")
    bool_int_convert(val)
  end

  def login_allowed=(value)
    Puppet.debug("entering login_allowed=value with name: #{resource[:account_name]} and login_allowed #{resource[:login_allowed]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          Puppet.debug("setting loginAllowed to #{bool_int_convert(value)}")
          entry.loginAllowed = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
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
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          val = entry.term.shellAccessType
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          val = entry.term.shellAccessType
        end
      end
    end
    Puppet.debug("value of shell_access_type is #{val} and converted to be returned is #{shell_access_type_convert(val)}")
    shell_access_type_convert(val)
  end

  def shell_access_type=(value)
    Puppet.debug("entering shell_access_type=value with account_name: #{resource[:account_name]} and shell_access_type #{resource[:shell_access_type]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          Puppet.debug("setting shellAccessType to #{shell_access_type_convert(value)}")
          entry.term.shellAccessType = shell_access_type_convert(value)
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          Puppet.debug("setting shellAccessType to #{shell_access_type_convert(value)}")
          entry.term.shellAccessType = shell_access_type_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def specify_group
    Puppet.debug('entering specify_group getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          val = entry.specifyGroup
        end
      end
    else # Virtual account
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          val = entry.specifyGroup
        end
      end
    end
    Puppet.debug("value of specify_group found is #{val}, value converted to be returned is #{bool_int_convert(val)}")
    bool_int_convert(val)
  end

  def specify_group=(value)
    Puppet.debug("entering specify_group=value with name: #{resource[:account_name]} and specify_group #{resource[:specify_group]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          Puppet.debug("setting specifyGroup to #{bool_int_convert(value)}")
          entry.specifyGroup = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          Puppet.debug("setting specifyGroup to #{bool_int_convert(value)}")
          entry.specifyGroup = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def group
    Puppet.debug('entering group getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          val = entry.group
        end
      end
    else # Virtual account
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          val = entry.group
        end
      end
    end
    Puppet.debug("value of group found is #{val}, value converted to be returned is #{val}")
    val
  end

  def group=(value)
    Puppet.debug("entering group=value with name: #{resource[:account_name]} and group #{resource[:group]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          Puppet.debug("setting group to #{value}")
          entry.group = value
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          Puppet.debug("setting group to #{value}")
          entry.group = value
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def win_account
    Puppet.debug('entering win_account getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          val = entry.winAccount
        end
      end
    else # Virtual account
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          val = entry.winAccount
        end
      end
    end
    Puppet.debug("value of win_account found is #{val}, value converted to be returned is #{val}")
    val
  end

  def win_account=(value)
    Puppet.debug("entering win_account=value with name: #{resource[:account_name]} and win_account #{resource[:win_account]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          Puppet.debug("setting winAccount to #{value}")
          entry.winAccount = value
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          Puppet.debug("setting winAccount to #{value}")
          entry.winAccount = value
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def win_domain
    Puppet.debug('entering win_domain getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          val = entry.winDomain
        end
      end
    else # Virtual account
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          val = entry.winDomain
        end
      end
    end
    Puppet.debug("value of win_domain found is #{val}, value converted to be returned is #{val}")
    val
  end

  def win_domain=(value)
    Puppet.debug("entering win_domain=value with name: #{resource[:account_name]} and win_domain #{resource[:win_domain]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          Puppet.debug("setting winDomain to #{value}")
          entry.winDomain = value
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          Puppet.debug("setting winDomain to #{value}")
          entry.winDomain = value
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def security_context
    Puppet.debug('entering security_context getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          val = entry.securityContext
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          val = entry.securityContext
        end
      end
    end
    Puppet.debug("value of security_context is #{val} and converted to be returned is #{security_context_convert(val)}")
    security_context_convert(val)
  end

  def security_context=(value)
    Puppet.debug("entering security_context=value with account_name: #{resource[:account_name]} and security_context #{resource[:security_context]} and value #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          Puppet.debug("setting securityContext to #{security_context_convert(value)}")
          entry.securityContext = security_context_convert(value)
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          Puppet.debug("setting shellAccessType to #{security_context_convert(value)}")
          entry.securityContext = security_context_convert(value)
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
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.new.SetDefaults()
      cfg.settings.access.winAccounts.new.winAccount = resource[:account_name]
      cfg.settings.access.winAccounts.new.specifyGroup = resource[:specify_group]
      cfg.settings.access.winAccounts.new.groupType = group_type_convert(resource[:group_type]) unless resource[:group_type].nil? # optional if specify_group is false
      cfg.settings.access.winAccounts.new.group = resource[:group] unless resource[:group].nil? # optional if specify_group is false
      cfg.settings.access.winAccounts.new.loginAllowed = bool_int_convert(resource[:login_allowed])
      cfg.settings.access.winAccounts.new.term.SetDefaults()
      cfg.settings.access.winAccounts.new.term.shellAccessType = shell_access_type_convert(resource[:shell_access_type])
      # TODO: keys
      cfg.settings.access.winAccounts.NewCommit()
    else # Virtual group
      cfg.settings.access.virtAccounts.new.SetDefaults()
      cfg.settings.access.virtAccounts.new.virtAccount = resource[:account_name]
      cfg.settings.access.virtAccounts.new.group = resource[:group] unless resource[:group].nil?
      cfg.settings.access.virtAccounts.new.loginAllowed = bool_int_convert(resource[:login_allowed])
      cfg.settings.access.virtAccounts.new.securityContext = security_context_convert(resource[:security_context])
      cfg.settings.access.virtAccounts.new.winAccount = resource[:win_account] unless resource[:win_account].nil?
      cfg.settings.access.virtAccounts.new.winDomain = resource[:win_domain] unless resource[:win_domain].nil?
      cfg.settings.access.virtAccounts.new.term.SetDefaults()
      cfg.settings.access.virtAccounts.new.term.shellAccessType = shell_access_type_convert(resource[:shell_access_type])
      # TODO: keys
      cfg.settings.access.virtAccounts.NewCommit()
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
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each_with_index do |entry, index|
        if entry.winAccount == resource[:group_name]
          i = index
        end
      end
      cfg.settings.access.winAccounts.Erase(i) unless i.nil?
    else
      cfg.settings.access.virtAccounts.entries.each_with_index do |entry, index|
        if entry.virtAccount == resource[:group_name]
          i = index
        end
      end
      cfg.settings.access.virtAccounts.Erase(i) unless i.nil?
    end
    cfg.settings.save
    cfg.settings.unlock
  end
end
