#
Puppet::Type.type(:bitvise_group).provide(:bsscfg) do
  desc 'This provider manages bitvise windows groups'

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

  def logon_type_convert(val)
    values = {
      'interactive' => 1,
      'network'     => 2,
      'bash'        => 3
    }
    r = val.is_a?(Integer) ? values.invert[val] : values[val.to_s]
    r
  end

  def account_failure_convert(val)
    values = {
      'deny login'       => 1,
      'restrict access'  => 2,
      'disable profile'  => 3,
       'no restrictions' => 4
    }
    r = val.is_a?(Integer) ? values.invert[val] : values[val.to_s]
    r
  end

  def display_time_convert(val)
    values = {
      'local with offset' => 1,
      'local'             => 2,
      'UTC'               => 3
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
    cfg = WIN32OLE.new(cfg_object)
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

  # If ensure => present is set and exists? returns false this method is called to create the group
  def create
    cfg = WIN32OLE.new(cfg_object)
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
        if cfg_major_version == 9
          cfg.settings.access.winGroups.new.xfer.mountPoints.new.fileSharingDl = mount['file_sharing_dl'] unless mount['file_sharing_dl'].nil?
        else
          cfg.settings.access.winGroups.new.xfer.mountPoints.new.fileSharing = mount['file_sharing_dl'] unless mount['file_sharing_dl'].nil?
        end
        cfg.settings.access.winGroups.new.xfer.mountPoints.NewCommit()
      end
      cfg.settings.access.winGroups.new.xfer.sfsHomeDir = resource[:sfs_home_dir]
      # Listen rules
      cfg.settings.access.winGroups.new.fwding.SetDefaults()
      cfg.settings.access.winGroups.new.fwding.listenRules.Clear()
      resource[:listen_rules].each do |rule|
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
        cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.Clear() unless rule['accept_rules'].empty?
        rule['accept_rules'].each do |r|
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.new.SetDefaults()
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.SetDefaults()
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.addressType = r['address_type'] unless r['address_type'].nil?
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.ipv4range = r['ipv4_range'] unless r['ipv4_range'].nil?
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.new.addressRule.ipv4end = r['ipv4_end'] unless r['ipv4_end'].nil?
          cfg.settings.access.winGroups.new.fwding.listenRules.new.instr.acceptRules.NewCommit()
        end
        cfg.settings.access.winGroups.new.fwding.listenRules.NewCommit()
      end
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
        if cfg_major_version == 9
          cfg.settings.access.virtGroups.new.xfer.mountPoints.new.fileSharingDl = mount['file_sharing_dl'] unless mount['file_sharing_dl'].nil?
        else
          cfg.settings.access.virtGroups.new.xfer.mountPoints.new.fileSharing = mount['file_sharing_dl'] unless mount['file_sharing_dl'].nil?
        end
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
  end

  # If ensure => absent is set and exists? returns true this method is called to destroy the group
  def destroy
    cfg = WIN32OLE.new(cfg_object)
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

  ##                       ##
  ## Getter/Setter Methods ##
  ##                       ##

  def login_allowed
    cfg = WIN32OLE.new(cfg_object)
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
    bool_int_convert(val)
  end

  def login_allowed=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.loginAllowed = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
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
    shell_access_type_convert(val)
  end

  def shell_access_type=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.term.shellAccessType = shell_access_type_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.term.shellAccessType = shell_access_type_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def logon_type
    cfg = WIN32OLE.new(cfg_object)
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
    logon_type_convert(val)
  end

  def logon_type=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.session.logonType = logon_type_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.session.logonType = logon_type_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def on_account_info_failure
    cfg = WIN32OLE.new(cfg_object)
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
    account_failure_convert(val)
  end

  def on_account_info_failure=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.session.onAccountInfoFailure = account_failure_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.session.onAccountInfoFailure = account_failure_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def max_wait_time
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    val = nil
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = (cfg_major_version == 9) ? entry.session.windowsOnLogonCmd.maxWaitTime : entry.session.onUploadCmd.maxWaitTime
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          val = (cfg_major_version == 9) ? entry.session.windowsOnLogonCmd.maxWaitTime : entry.session.onUploadCmd.maxWaitTime
        end
      end
    end
    val
  end

  def max_wait_time=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          if cfg_major_version == 9
            entry.session.windowsOnLogonCmd.maxWaitTime = value
          else
            entry.session.onUploadCmd.maxWaitTime = value
          end
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          if cfg_major_version == 9
            entry.session.windowsOnLogonCmd.maxWaitTime = value
          else
            entry.session.onUploadCmd.maxWaitTime = value
          end
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def permit_init_dir_fallback
    cfg = WIN32OLE.new(cfg_object)
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
    bool_int_convert(val)
  end

  def permit_init_dir_fallback=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.term.permitInitDirFallback = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.term.permitInitDirFallback = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def allow_agent_fwd_cygwin
    cfg = WIN32OLE.new(cfg_object)
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
    bool_int_convert(val)
  end

  def allow_agent_fwd_cygwin=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.term.allowAgentFwdCygwin = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.term.allowAgentFwdCygwin = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def allow_agent_fqd_putty
    cfg = WIN32OLE.new(cfg_object)
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
    bool_int_convert(val)
  end

  def allow_agent_fqd_putty=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.term.allowAgentFwdPutty = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.term.allowAgentFwdPutty = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def load_profile_for_file_xfer
    cfg = WIN32OLE.new(cfg_object)
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
    bool_int_convert(val)
  end

  def load_profile_for_file_xfer=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.xfer.loadProfileForFileXfer = bool_int_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.xfer.loadProfileForFileXfer = bool_int_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def display_time
    cfg = WIN32OLE.new(cfg_object)
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
    display_time_convert(val)
  end

  def display_time=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.xfer.displayTime = display_time_convert(value)
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.xfer.displayTime = display_time_convert(value)
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def sfs_home_dir
    cfg = WIN32OLE.new(cfg_object)
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
    val
  end

  def sfs_home_dir=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    if resource[:type] == 'windows'
      cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.xfer.sfsHomeDir = value
        end
      end
    else
      cfg.settings.access.virtGroups.entries.each do |entry|
        if entry.group == resource[:group_name]
          entry.xfer.sfsHomeDir = value
        end
      end
    end
    cfg.settings.save
    cfg.settings.unlock
  end

  def mounts
      Puppet.debug("entering mounts getter with group_name: #{resource[:group_name]} and value #{resource[:mounts]}")
      cfg = WIN32OLE.new(cfg_object())
      cfg.settings.load
      arr = []
      if resource[:type] == 'windows'
        cfg.settings.access.winGroups.entries.each do | entry |
          if entry.group == resource[:group_name]
            entry.xfer.mountPoints.entries.each do | mount |
              hash = {}
              hash['sfsMountPath'] = mount.sfsMountPath
              hash['fileSharingBeh'] = mount.fileSharingBeh
              hash['fileSharingDl'] = mount.fileSharingDl
              hash['realRootPath'] = mount.realRootPath
              hash['allowUnlimitedAccess'] = mount.allowUnlimitedAccess
              arr.push(hash)
            end
          end
        end
      else
        cfg.settings.access.virtGroups.entries.each do | entry |
          if entry.group == resource[:group_name]
            entry.xfer.mountPoints.entries.each do | mount |
              hash = {}
              hash['sfsMountPath'] = mount.sfsMountPath
              hash['fileSharingBeh'] = mount.fileSharingBeh
              hash['fileSharingDl'] = mount.fileSharingDl
              hash['realRootPath'] = mount.realRootPath
              hash['allowUnlimitedAccess'] = mount.allowUnlimitedAccess
              arr.push(hash)
            end
          end
        end
      end
      Puppet.debug("value of mounts is #{arr}}")
      arr
  end

  def mounts=(value)
    #   Puppet.debug("entering mounts=value with group_name: #{resource[:group_name]} and mounts #{resource[:mounts]} and value #{value}")
    #   cfg = WIN32OLE.new(cfg_object())
    #   cfg.settings.load
    #   cfg.settings.lock
    #   if resource[:type] == 'windows'
    #     cfg.settings.access.winGroups.entries.each do |entry|
    #       if entry.group == resource[:group_name]
    #         Puppet.debug("setting mounts to #{value}")
    #         entry.xfer.mountPoints.sfsMountPath = value
    #       end
    #     end
    #   else
    #     cfg.settings.access.virtGroups.entries.each do |entry|
    #       if entry.group == resource[:group_name]
    #         Puppet.debug("setting mounts to #{value}")
    #         entry.xfer.mountPoints.sfsMountPath = value
    #       end
    #     end
    #   end
    #   cfg.settings.save
    #   cfg.settings.unlock
  end

  def listen_rules
    #   Puppet.debug("entering listen_rules getter with group_name: #{resource[:group_name]} and value #{resource[:listen_rules]}")
    #   cfg = WIN32OLE.new(cfg_object())
    #   cfg.settings.load
    #   val = nil
    #   if resource[:type] == 'windows'
    #     cfg.settings.access.winGroups.entries.each do |entry|
    #       if entry.group == resource[:group_name]
    #         val = entry.fwding.listenRules.intfRule
    #       end
    #     end
    #   else
    #     cfg.settings.access.virtGroups.entries.each do |entry|
    #       if entry.group == resource[:group_name]
    #         val = entry.fwding.listenRules.intfRule
    #       end
    #     end
    #   end
    #   Puppet.debug("value of listen_rules is #{val}}")
    #   val
    # Temporarily returrn this as always matching until we get the getter/setter working
    resource[:listen_rules]
  end

  def listen_rules=(value)
    #   Puppet.debug("entering listen_rules=value with group_name: #{resource[:group_name]} and listen_rules #{resource[:listen_rules]} and value #{value}")
    #   cfg = WIN32OLE.new(cfg_object())
    #   cfg.settings.load
    #   cfg.settings.lock
    #   if resource[:type] == 'windows'
    #     cfg.settings.access.winGroups.entries.each do |entry|
    #       if entry.group == resource[:group_name]
    #         Puppet.debug("setting listenRules to #{value}")
    #         entry.fwding.listenRules.intfRule = value
    #       end
    #     end
    #   else
    #     cfg.settings.access.virtGroups.entries.each do |entry|
    #       if entry.group == resource[:group_name]
    #         Puppet.debug("setting listenRules to #{value}")
    #         entry.fwding.listenRules.intfRule = value
    #       end
    #     end
    #   end
    #   cfg.settings.save
    #   cfg.settings.unlock
  end
end
