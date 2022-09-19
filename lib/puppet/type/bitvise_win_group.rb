#
# TODO documentation
# * DONE prove we can modify configuration via the COM object for a sample config (trusted_lsp_only)
# TODO prove we can add groups
# TODO add virtual users
# TODO add virtual groups
# TODO add certs
# TODO add license
# TODO gather other config requirements
# TODO accept true/false instead of 1/0
#
Puppet::Type.newtype(:bitvise_win_group) do
  @doc = <<-PUPPET
            @summary
            Manages bitvise windows groups.
            PUPPET

  ensurable

  newparam(:name) do
    desc 'The name of the windows group.'

    isnamevar
  end

  newparam(:group_name) do
    desc 'The name of the windows group.'
  end

  newparam(:type) do
    desc 'The name of the windows group.'

    validate do |value|
      unless ['windows', 'virtual'].include? value
        raise ArgumentError, 'type must be windows or virtual'
      end
    end
  end

  newproperty(:login_allowed) do
    desc 'The login_allowed setting'

    newvalue(false)
    newvalue(true)
    defaultto(false) # TODO: does this need to be :false :true ?
    munge { |value| value }
  end

  newproperty(:shell_access_type) do
    desc 'The shell_access_type setting. Valid options are: default, none, BvShell, cmd, PowerShell, Bash, Git, Telnet, Custom.
        Defaults to: cmd'

    newvalue('default') # 1
    newvalue('none') # 2
    newvalue('BvShell') # 10
    newvalue('cmd') # 3
    newvalue('PowerShell') # 4
    newvalue('Bash') # 5
    newvalue('Git') # 6
    newvalue('Telnet') # 9
    newvalue('Custom') # 7
    defaultto('cmd')
  end

  newparam(:group_type) do
    desc 'The shell_access_type setting. Valid options are: default, none, BvShell, cmd, PowerShell, Bash, Git, Telnet, Custom.
        Defaults to: cmd'

    validate do |value|
        unless ['everyone', 'local', 'domain'].include? value
            raise ArgumentError, 'group_type must be everyone, local, or domain'
        end
    end
  end

  newparam(:domain) do
    desc 'The domain to be used for domain accounts and groups.'
  end

  newproperty(:logon_type) do
    desc 'Logon type. Valid values are: interactie, network, bash. Default is: network.'

    newvalue('interactive') # 1
    newvalue('network') # 2
    newvalue('bash') # 3
    defaultto('network')
  end
end
