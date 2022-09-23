#
Puppet::Type.type(:bitvise_setting).provide(:bsscfg) do
  desc 'This provider manages bitvise settings'

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
    Puppet.debug("bool_int_convert with val = #{val} and [true, false].include? val #{[true, false].include? val}")
    values = {
      false: 0,
      true: 1
    }
    r = [:true, :false].include?(val) ? values[val] : values.invert[val]
    Puppet.debug("bool_int_convert with r = #{r}")
    r
  end

  # Returns the major version of the bitvise config
  def cfg_major_version
    cfg = WIN32OLE.new(cfg_object)
    cfg.version.cfgFormatVersion.split('.')[0].to_i
  end

  ##                       ##
  ## Getter/Setter Methods ##
  ##                       ##

  def send_fwding_rule_descs
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    val = cfg.settings.server.sendFwdingRuleDescs
    bool_int_convert(val)
  end

  def send_fwding_rule_descs=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.server.sendFwdingRuleDescs = bool_int_convert(value)
    cfg.settings.save
    cfg.settings.unlock
  end

  def log_file_rollover_by_size
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    val = cfg.settings.logging.logFileRolloverBySize
    bool_int_convert(val)
  end

  def log_file_rollover_by_size=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.logging.logFileRolloverBySize = bool_int_convert(value)
    cfg.settings.save
    cfg.settings.unlock
  end

  def ssh_dss
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    val = cfg.settings.algs.sig.sshDss
    bool_int_convert(val)
  end

  def ssh_dss=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.algs.sig.sshDss = bool_int_convert(value)
    cfg.settings.save
    cfg.settings.unlock
  end

  def alg_3des_ctr
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    val = cfg.settings.algs.encr.alg_3des_ctr
    bool_int_convert(val)
  end

  def alg_3des_ctr=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.algs.encr.alg_3des_ctr = bool_int_convert(value)
    cfg.settings.save
    cfg.settings.unlock
  end

  def min_rsa_key_bits
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    val = cfg.settings.algs.sig.minRsaKeyBits
    val
  end

  def min_rsa_key_bits=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.algs.sig.minRsaKeyBits = value
    cfg.settings.save
    cfg.settings.unlock
  end

  def min_dsa_key_bits
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    val = cfg.settings.algs.sig.minDsaKeyBits
    val
  end

  def min_dsa_key_bits=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.algs.sig.minDsaKeyBits = value
    cfg.settings.save
    cfg.settings.unlock
  end

  def total_threshold
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    val = cfg.settings.ipBlock.totalThreshold
    val
  end

  def total_threshold=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.ipBlock.totalThreshold = value
    cfg.settings.save
    cfg.settings.unlock
  end

  def lockout_mins
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    val = cfg.settings.ipBlock.lockoutMins
    val
  end

  def lockout_mins=(value)
    cfg = WIN32OLE.new(cfg_object)
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.ipBlock.lockoutMins = value
    cfg.settings.save
    cfg.settings.unlock
  end

  def client_versions
    # cfg = WIN32OLE.new(cfg_object)
    # cfg.settings.load
    # val = cfg.settings.access.clientVersions.entries
    # val
    # Temporarily always match until we get the getter working
    resource[:client_versions]
  end

  def client_versions=(value)
    # cfg = WIN32OLE.new(cfg_object)
    # cfg.settings.load
    # cfg.settings.lock
    # cfg.settings.access.clientVersions.entries.each do | entry |
    #     entry.matchAll = value['matchAll']
    # end
    # cfg.settings.save
    # cfg.settings.unlock
  end
end
