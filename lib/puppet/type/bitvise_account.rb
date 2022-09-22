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
Puppet::Type.newtype(:bitvise_account) do
  @doc = <<-PUPPET
              @summary
              Manages bitvise accounts.
              PUPPET

  ensurable

  newparam(:name) do
    desc 'The name of the account.'

    isnamevar
  end

  newparam(:account_name) do
    desc 'The name of the account.'
  end

  newparam(:com) do
    desc 'The name of the com object for your version.'
  end

  newparam(:account_type) do
    desc 'The type of the account. Valid values: windows, virtual. Defaults to: windows'
    validate do |value|
      unless ['windows', 'virtual'].include? value
        raise ArgumentError, 'account_type must be windows or virtual'
      end
    end
  end

  newproperty(:specify_group) do
    desc 'Valid values: true, false. Defaults to false'
    newvalue(:false)
    newvalue(:true)
    defaultto(:false)
  end

  newparam(:group_type) do
    desc 'The group_type setting. Valid options are: everyone, local, domain.
            Defaults to: cmd'

    validate do |value|
      unless ['everyone', 'local', 'domain'].include? value
        raise ArgumentError, 'group_type must be everyone, local, or domain'
      end
    end
  end

  newproperty(:group) do
    desc 'The name of the group. Valid values: String'
  end

  newproperty(:win_account) do
    desc 'The name of the win_account. Valid values: String'
  end

  newproperty(:win_domain) do
    desc 'The name of the win_domain. Valid values: String'
  end

  newproperty(:security_context) do
    desc 'The security context. Valid values: default, auto, local, domain, service, microsoft. Defualt: default.
      This setting only applies when account_type = virtual.'

    newvalue('default') # 0
    newvalue('auto') # 1
    newvalue('local') # 2
    newvalue('domain') # 3
    newvalue('service') # 4
    newvalue('microsoft') # 5
  end

  newproperty(:login_allowed) do
    desc 'The login_allowed setting'

    newvalue(:false)
    newvalue(:true)
    defaultto(:false)
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

  newproperty(:keys, array_matching: :all) do
    desc 'The public keys to import.'
  end
end
