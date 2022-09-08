require 'win32ole'

Puppet::Type.type(:bitvise).provide(:bsscfg) do
  desc 'This provider manages vault policies.'

  defaultfor kernel: :windows
  confine    kernel: :windows

  def restart_service
    Puppet.debug('restarting service')
    `net stop BvSshServer`
    `net start BvSshServer`
    Puppet.debug('restarted service')
  end

  def exists?
    Puppet.debug('entering exists?')
    # for now do nothing, settings will always exist w/ defaults
    true
  end

  def trustedLspOnly
    Puppet.debug('entering trustedLspOnly getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = cfg.settings.server.trustedLspOnly
    Puppet.debug("value of trustedLspOnly is #{val}")
    val
  end

  def trustedLspOnly=(value)
    Puppet.debug("entering trustedLspOnly=value with name: #{resource[:name]} and trustedLspOnly #{resource[:trustedLspOnly]}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.server.trustedLspOnly = value
    cfg.settings.save
    cfg.settings.unlock
    restart_service()
  end

  def create
    Puppet.debug('entering create')
    # do nothing since we never need to create, only modify
  end

  def destroy
    Puppet.debug('entering destroy')
    # do nothing since we never need to destroy a setting
  end
end
