#
# TODO documentation
# TODO remove restart_service and handle as a puppet resource
# TODO figure out approach for exists, create, destroy
# TODO remove trusted_lsp_only since it was only for testing
# TODO add groups
# TODO handle fg = WIN32OLE.new(resource[:com_object]) accross multiple versions, how do we query for version?
# TODO do we create a WIN32OLE.new() for each method? Can this be global? Need to find examples of best practice
# * create re-usable code for load, lock, set, save, unlock
# TODO if we continue to use eval make sure strings are appropriately contained
# TODO stop on error
#
Puppet::Type.type(:bitvise_setting).provide(:bsscfg) do
  desc 'This provider manages bitvise settings'

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
      false: 0,
      true: 1
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
    # This depends on bitvise already being installed, will fail if not installed
    true
  end

  def send_fwding_rule_descs
    Puppet.debug('entering send_fwding_rule_descs getter')
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    val = cfg.settings.server.sendFwdingRuleDescs
    Puppet.debug("value of send_fwding_rule_descs found is #{val}, value converted to be returned is #{bool_int_convert(val)}")
    bool_int_convert(val)
  end

  def send_fwding_rule_descs=(value)
    Puppet.debug("entering send_fwding_rule_descs=value with send_fwding_rule_descs #{resource[:send_fwding_rule_descs]} and value #{value}")
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.server.sendFwdingRuleDescs = bool_int_convert(value)
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def log_file_rollover_by_size
    Puppet.debug("entering log_file_rollover_by_size getter with resource set to #{resource[:log_file_rollover_by_size]}")
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    val = cfg.settings.logging.logFileRolloverBySize
    Puppet.debug("value of log_file_rollover_by_size found is #{val}, value converted to be returned is #{bool_int_convert(val)}")
    bool_int_convert(val)
  end

  def log_file_rollover_by_size=(value)
    Puppet.debug("entering log_file_rollover_by_size=value with log_file_rollover_by_size #{resource[:log_file_rollover_by_size]} and value #{value}")
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.logging.logFileRolloverBySize = bool_int_convert(value)
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def ssh_dss
    Puppet.debug('entering ssh_dss getter')
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    val = cfg.settings.algs.sig.sshDss
    Puppet.debug("value of ssh_dss found is #{val}, value converted to be returned is #{bool_int_convert(val)}")
    bool_int_convert(val)
  end

  def ssh_dss=(value)
    Puppet.debug("entering ssh_dss=value with ssh_dss #{resource[:ssh_dss]} and value #{value}")
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.algs.sig.sshDss = bool_int_convert(value)
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def alg_3des_ctr
    Puppet.debug('entering alg_3des_ctr getter')
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    val = cfg.settings.algs.encr.alg_3des_ctr
    Puppet.debug("value of alg_3des_ctr found is #{val}, value converted to be returned is #{bool_int_convert(val)}")
    bool_int_convert(val)
  end

  def alg_3des_ctr=(value)
    Puppet.debug("entering alg_3des_ctr=value with alg_3des_ctr #{resource[:alg_3des_ctr]} and value #{value}")
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.algs.encr.alg_3des_ctr = bool_int_convert(value)
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def min_rsa_key_bits
    Puppet.debug('entering min_rsa_key_bits getter')
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    val = cfg.settings.algs.sig.minRsaKeyBits
    Puppet.debug("value of min_rsa_key_bits found is #{val}")
    val
  end

  def min_rsa_key_bits=(value)
    Puppet.debug("entering min_rsa_key_bits=value with min_rsa_key_bits #{resource[:min_rsa_key_bits]} and value #{value}")
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.algs.sig.minRsaKeyBits = resource[:min_rsa_key_bits]
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def min_dsa_key_bits
    Puppet.debug('entering min_dsa_key_bits getter')
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    val = cfg.settings.algs.sig.minDsaKeyBits
    Puppet.debug("value of min_dsa_key_bits found is #{val}")
    val
  end

  def min_dsa_key_bits=(value)
    Puppet.debug("entering min_dsa_key_bits=value with min_dsa_key_bits #{resource[:min_dsa_key_bits]} and value #{value}")
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.algs.sig.minDsaKeyBits = resource[:min_dsa_key_bits]
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def total_threshold
    Puppet.debug('entering total_threshold getter')
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    val = cfg.settings.ipBlock.totalThreshold
    Puppet.debug("value of total_threshold found is #{val}")
    val
  end

  def total_threshold=(value)
    Puppet.debug("entering total_threshold=value with total_threshold #{resource[:total_threshold]} and value #{value}")
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.ipBlock.totalThreshold = resource[:total_threshold]
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def lockout_mins
    Puppet.debug('entering lockout_mins getter')
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    val = cfg.settings.ipBlock.lockoutMins
    Puppet.debug("value of lockout_mins found is #{val}")
    val
  end

  def lockout_mins=(value)
    Puppet.debug("entering lockout_mins=value with lockout_mins #{resource[:lockout_mins]} and value #{value}")
    cfg = WIN32OLE.new(resource[:com_object])
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.ipBlock.lockoutMins = resource[:lockout_mins]
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def create
    # Nothing to do
  end

  def destroy
    # Nothing to do
  end
end
