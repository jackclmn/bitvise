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

  def restart_service
    Puppet.debug('restarting service')
    `net stop BvSshServer`
    `net start BvSshServer`
    Puppet.debug('restarted service')
  end

  def exists?
    Puppet.debug('entering exists?')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.access.winGroups.entries.each do |entry|
      if entry.group == resource[:name]
        return true
      end
    end
    false
  end

  def login_allowed
    Puppet.debug('entering login_allowed getter')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    val = nil
    cfg.settings.access.winGroups.entries.each do |entry|
      if entry.group == resource[:name]
        val = entry.loginAllowed
      end
    end
    Puppet.debug("value of login_allowed is #{val}")
    val
  end

  def login_allowed=(value)
    Puppet.debug("entering login_allowed=value with name: #{resource[:name]} and login_allowed #{resource[:login_allowed]}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.access.winGroups.entries.each do |entry|
      if entry.group == resource[:name]
        entry.loginAllowed = value
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
    cfg.settings.access.winGroups.entries.each do |entry|
      if entry.group == resource[:name]
        val = entry.term.shellAccessType
      end
    end
    Puppet.debug("value of shell_access_type is #{val}")
    val
  end

  def shell_access_type=(value)
    Puppet.debug("entering shell_access_type=value with name: #{resource[:name]} and shell_access_type #{resource[:shell_access_type]}")
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.lock
    cfg.settings.access.winGroups.entries.each do |entry|
      if entry.group == resource[:name]
        entry.term.shellAccessType = value
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
    cfg.settings.access.winGroups.new.groupType = 1 # $cfg.enums.GroupType.local
    cfg.settings.access.winGroups.new.group = resource[:name]
    cfg.settings.access.winGroups.new.loginAllowed = resource[:login_allowed]
    cfg.settings.access.winGroups.new.term.shellAccessType = resource[:shell_access_type]
    cfg.settings.save
    cfg.settings.unlock
    restart_service
  end

  def destroy
    Puppet.debug('entering destroy')
    cfg = WIN32OLE.new('Bitvise.BssCfg')
    cfg.settings.load
    cfg.settings.access.winGroups.entries.each do |entry|
        if entry.group == resource[:name]
          entry.erase
        end
      end
  end
end
