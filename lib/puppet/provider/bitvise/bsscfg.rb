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
Puppet::Type.type(:bitvise).provide(:bsscfg) do
  desc 'This provider manages vault policies.'

  defaultfor kernel: :windows
  confine    kernel: :windows

  require 'win32ole'

  def restart_service
    Puppet.debug('restarting service')
    `net stop BvSshServer`
    `net start BvSshServer`
    Puppet.debug('restarted service')
  end

  # TODO: add data types for method parameters
  def get_config(setting)
    Puppet.debug("get_config with setting: #{setting}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = cfg.settings.server.send(setting)
    val
  end

  # TODO: add data types for method parameters
  def set_config(setting, value)
    Puppet.debug("set_config with setting: #{setting} and value: #{value}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    eval "cfg.settings.server.#{setting} = #{value}"
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def exists?
    Puppet.debug('entering exists?')
    # TODO: for now do nothing, settings will always exist w/ defaults
    true
  end

  def trusted_lsp_only
    Puppet.debug('entering trusted_lsp_only getter')
    val = get_config('trustedLspOnly')
    Puppet.debug("value of trusted_lsp_only is #{val}")
    val
  end

  def trusted_lsp_only=(value)
    Puppet.debug("entering trusted_lsp_only=value with name: #{resource[:name]} and trusted_lsp_only #{resource[:trusted_lsp_only]}")
    set_config('trustedLspOnly', value)
  end

  def create
    Puppet.debug('entering create')
    # TODO: do nothing since we never need to create, only modify
  end

  def destroy
    Puppet.debug('entering destroy')
    # TODO: do nothing since we never need to destroy a setting
  end
end
