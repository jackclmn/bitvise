Facter.add('bitvise_version') do
    confine    kernel: :windows

    require 'win32ole'

    setcode do
        keys = nil
        Win32::Registry::HKEY_LOCAL_MACHINE.open('SOFTWARE\Classes') do |regkey|
          keys = regkey.keys
        end
        cfg_object = keys.select { |i| i[%r{^\w+\.\w+$}] }.select { |i| i[%r{BssCfg}] }[0]
        cfg = WIN32OLE.new(cfg_object)
        cfg.version.cfgFormatVersion
    end
end