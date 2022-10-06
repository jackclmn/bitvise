Facter.add('bitvise_version') do
  confine kernel: :windows
  
  if Puppet::Util::Platform.windows?
    require 'win32ole'
  end

  setcode do
    keys = nil
    Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Classes') do |regkey|
      keys = regkey.keys
    end
    cfg_object = keys.select { |i| i[%r{^\w+\.\w+$}] }.select { |i| i[%r{BssCfg}] }[0]
    cfg = WIN32OLE.new(cfg_object)
    version = cfg.version.buildVersion.split('.')
    if version.length > 2
      version.join('.')
    else
      "#{version.join('.')}.0"
    end
  end
end
