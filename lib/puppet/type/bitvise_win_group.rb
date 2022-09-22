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

  newparam(:com_object) do
    desc 'The name of the com object for your version.'
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

  newparam(:group_type) do
    desc 'The group_type setting. Valid options are: everyone, local, domain.
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

  newproperty(:on_account_info_failure) do
    desc 'on_account_info_failure. Valid values are: deny login, restrict access, disable profile, no restrictions. Default is: restrict access.'

    newvalue('deny login') # 1
    newvalue('restrict access') # 2
    newvalue('disable profile') # 3
    newvalue('no restrictions') # 4
    defaultto('restrict access')
  end

  newproperty(:max_wait_time) do
    desc 'max_wait_time. Valid values are: any integer. Default is: 0.'

    defaultto(300)

    validate do |value|
      raise Puppet::Error, _('must be a number') unless value.is_a?(Integer)
      super(value)
    end

    # override default munging of newvalue() to symbol, treating input as number
    munge { |value| value }
  end

  newproperty(:permit_init_dir_fallback) do
    desc 'The permit_init_dir_fallback setting. Valid values: true, false. Default: true'

    newvalue(:false)
    newvalue(:true)
    defaultto(:true)
  end

  newproperty(:allow_agent_fwd_cygwin) do
    desc 'The allow_agent_fwd_cygwin setting. Valid values: true, false. Default: true'

    newvalue(:false)
    newvalue(:true)
    defaultto(:true)
  end

  newproperty(:allow_agent_fqd_putty) do
    desc 'The allow_agent_fqd_putty setting. Valid values: true, false. Default: true'

    newvalue(:false)
    newvalue(:true)
    defaultto(:true)
  end

  newproperty(:load_profile_for_file_xfer) do
    desc 'The load_profile_for_file_xfer setting. Valid values: true, false. Default: false'

    newvalue(:false)
    newvalue(:true)
    defaultto(:false)
  end

  newproperty(:display_time) do
    desc 'The display_time setting. Valid values: local with offset, local, UTC. Default: local'

    newvalue('local with offset')
    newvalue('local')
    newvalue('UTC')
    defaultto('local')
  end

  newproperty(:sfs_home_dir) do
    desc 'The sfs_home_dir setting. Default: %HOME%'
    defaultto('/%HOME%')
  end

  newproperty(:mounts, array_matching: :all) do
    desc 'The mount points for the group. Default: none'
  end

  newproperty(:listen_rules, array_matching: :all) do
    desc 'The mount points for the group. Default: none'
  end
end
