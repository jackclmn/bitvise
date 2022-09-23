#
Puppet::Type.type(:bitvise_account).provide(:bsscfg) do
  desc 'This provider manages bitvise accounts'

  ##                   ##
  ## Provider Settings ##
  ##                   ##

  # Provider confines and defaults
  defaultfor kernel: :windows
  confine    kernel: :windows

  require 'win32ole'

  ##                ##
  ## Helper Methods ##
  ##                ##

  # Returns the BssCfg object
  def cfg_object
    keys = nil
    Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Classes') do |regkey|
      keys = regkey.keys
    end
    keys.select { |i| i[%r{^\w+\.\w+$}] }.select { |i| i[%r{BssCfg}] }[0]
  end

  # If we put in a boolean we get out an integer
  # If we put in an integer we get out a boolean
  # Used to convert 0/1s used by bsscfg to human readable values
  def bool_int_convert(val)
    values = {
      false: 0,
      true: 1
    }
    r = [:true, :false].include?(val) ? values[val] : values.invert[val]
    r
  end

  # Map the bitvise enumerations
  # String returns a corresponding integer, integer returns the corresponding string
  def shell_access_type_convert(val)
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
    r
  end

  def group_type_convert(val)
    values = {
      'everyone' => 0,
      'local'    => 1,
      'domain'   => 2
    }
    r = val.is_a?(Integer) ? values.invert[val] : values[val.to_s]
    r
  end

  def security_context_convert(val)
    values = {
      'default'   => 0,
      'auto'      => 1,
      'local'     => 2,
      'domain'    => 3,
      'service'   => 4,
      'microsoft' => 5
    }
    r = val.is_a?(Integer) ? values.invert[val] : values[val.to_s]
    r
  end

  # Returns the major version of the bitvise config
  def cfg_major_version
    cfg = WIN32OLE.new(cfg_object)
    cfg.version.cfgFormatVersion.split('.')[0].to_i
  end

  ##                   ##
  ## Ensurable Methods ##
  ##                   ##

  # This method determines if the account exists
  def exists?
    # load settings
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load

    # loop through windows or virtual accounts to find the matching account
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

  # If ensure => present is set and exists? returns false this method is called to create the account
  def create
    # Load and lock the settings so they cannot be modified while we are making changes
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock

    # Create either the windows or virtual account
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.new.SetDefaults()
      cfg.settings.access.winAccounts.new.winAccount = resource[:account_name]
      cfg.settings.access.winAccounts.new.specifyGroup = resource[:specify_group]
      cfg.settings.access.winAccounts.new.groupType = group_type_convert(resource[:group_type]) unless resource[:group_type].nil? # optional if specify_group is false
      cfg.settings.access.winAccounts.new.group = resource[:group] unless resource[:group].nil? # optional if specify_group is false
      cfg.settings.access.winAccounts.new.loginAllowed = bool_int_convert(resource[:login_allowed])
      cfg.settings.access.winAccounts.new.term.SetDefaults()
      cfg.settings.access.winAccounts.new.term.shellAccessType = shell_access_type_convert(resource[:shell_access_type])
      cfg.settings.access.winAccounts.NewCommit()
    else # Virtual account
      cfg.settings.access.virtAccounts.new.SetDefaults()
      cfg.settings.access.virtAccounts.new.virtAccount = resource[:account_name]
      cfg.settings.access.virtAccounts.new.group = resource[:group] unless resource[:group].nil?
      cfg.settings.access.virtAccounts.new.loginAllowed = bool_int_convert(resource[:login_allowed])
      cfg.settings.access.virtAccounts.new.securityContext = security_context_convert(resource[:security_context])
      cfg.settings.access.virtAccounts.new.winAccount = resource[:win_account] unless resource[:win_account].nil?
      cfg.settings.access.virtAccounts.new.winDomain = resource[:win_domain] unless resource[:win_domain].nil?
      cfg.settings.access.virtAccounts.new.term.SetDefaults()
      cfg.settings.access.virtAccounts.new.term.shellAccessType = shell_access_type_convert(resource[:shell_access_type])
      cfg.settings.access.virtAccounts.NewCommit()
    end

    # Import public keys once account is created
    resource[:keys].each do |key|
      if resource[:account_type] == 'windows'
        cfg.settings.access.winAccounts.entries.each do |entry|
          if entry.winAccount == resource[:account_name]
            entry.auth.keys.importFromBase64String(key)
          end
        end
      else # Virtual account
        cfg.settings.access.virtAccounts.entries.each do |entry|
          if entry.winAccount == resource[:account_name]
            entry.auth.keys.importFromBase64String(key)
          end
        end
      end
    end

    # Save settings and unlock when we are done
    cfg.settings.save
    cfg.settings.unlock
  end

  # If ensure => absent is set and exists? returns true this method is called to destroy the account
  def destroy
    # Load and lock settings
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock

    # Determine the index of the windows or virtual account we need to delete and delete it
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

    # Unlock settings when done
    cfg.settings.save
    cfg.settings.unlock
  end

  ##                       ##
  ## Getter/Setter Methods ##
  ##                       ##

  def login_allowed
    cfg = WIN32OLE.new(cfg_object)
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
    bool_int_convert(val)
  end

  def login_allowed=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          entry.loginAllowed = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          entry.loginAllowed = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def shell_access_type
    cfg = WIN32OLE.new(cfg_object)
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
    shell_access_type_convert(val)
  end

  def shell_access_type=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          entry.term.shellAccessType = shell_access_type_convert(value)
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          entry.term.shellAccessType = shell_access_type_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def specify_group
    cfg = WIN32OLE.new(cfg_object)
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
    bool_int_convert(val)
  end

  def specify_group=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          entry.specifyGroup = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          entry.specifyGroup = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def group
    cfg = WIN32OLE.new(cfg_object)
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
    val
  end

  def group=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          entry.group = value
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          entry.group = value
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def win_account
    cfg = WIN32OLE.new(cfg_object)
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
    val
  end

  def win_account=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          entry.winAccount = value
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          entry.winAccount = value
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def win_domain
    cfg = WIN32OLE.new(cfg_object)
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
    val
  end

  def win_domain=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          entry.winDomain = value
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          entry.winDomain = value
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def security_context
    cfg = WIN32OLE.new(cfg_object)
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
    security_context_convert(val)
  end

  def security_context=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:account_type] == 'windows'
      cfg.settings.access.winAccounts.entries.each do |entry|
        if entry.winAccount == resource[:account_name]
          entry.securityContext = security_context_convert(value)
        end
      end
    else
      cfg.settings.access.virtAccounts.entries.each do |entry|
        if entry.virtAccount == resource[:account_name]
          entry.securityContext = security_context_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def keys
    #   Puppet.debug('entering keys getter')
    #   cfg = WIN32OLE.new(cfg_object())
    #   cfg.settings.load
    #   val = nil
    #   if resource[:account_type] == 'windows'
    #     cfg.settings.access.winAccounts.entries.each do |entry|
    #       if entry.winAccount == resource[:account_name]
    #         val = entry.auth.keys
    #       end
    #     end
    #   else # Virtual account
    #     cfg.settings.access.virtAccounts.entries.each do |entry|
    #       if entry.virtAccount == resource[:account_name]
    #         val = entry.auth.keys
    #       end
    #     end
    #   end
    #   Puppet.debug("value of keys found is #{val}, value converted to be returned is #{val}")
    #   val
    resource[:keys]
  end

  def keys=(value)
    #   Puppet.debug("entering keys=value with name: #{resource[:account_name]} and keys #{resource[:keys]} and value #{value}")
    #   cfg = WIN32OLE.new(cfg_object())
    #   cfg.settings.load
    #   cfg.settings.lock
    #   if resource[:account_type] == 'windows'
    #     cfg.settings.access.winAccounts.entries.each do |entry|
    #       if entry.winAccount == resource[:account_name]
    #         Puppet.debug("setting keys to #{value}")
    #         entry.keys = value
    #       end
    #     end
    #   else
    #     cfg.settings.access.virtAccounts.entries.each do |entry|
    #       if entry.virtAccount == resource[:account_name]
    #         Puppet.debug("setting keys to #{value}")
    #         entry.keys = value
    #       end
    #     end
    #   end
    #   cfg.settings.save
    #   cfg.settings.unlock
  end
end
