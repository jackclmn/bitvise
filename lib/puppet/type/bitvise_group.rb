#
Puppet::Type.newtype(:bitvise_group) do
  @doc = <<-PUPPET
              @summary
              Manages bitvise groups.
              PUPPET

  ensurable

  newparam(:name) do
    desc 'The friendly name for this resource. This is the namevar for the resource but is not used.
    This allows multiple groups to have the same name (one virtual group and one windows group)
    without a duplicate resource declaration. Use group_name to specify the name.'

    isnamevar
  end

  newparam(:group_name) do
    desc 'The name of the windows group to be created.'

    validate do |value|
      raise ArgumentError, "Value must be a String'" unless value.is_a?(String)
    end
  end

  newparam(:type) do
    desc 'The type of group to be managed. Valid values: windows, virtual'

    validate do |value|
      unless ['windows', 'virtual'].include? value
        raise ArgumentError, 'type must be windows or virtual'
      end
    end
  end

  newproperty(:login_allowed) do
    desc 'The login_allowed setting'

    newvalues(:true, :false)

    defaultto(:false)
  end

  newproperty(:shell_access_type) do
    desc 'The shell_access_type setting. Valid options are: default, none, BvShell, cmd, PowerShell, Bash, Git, Telnet, Custom.
          Defaults to: cmd'

    newvalue('default')
    newvalue('none')
    newvalue('BvShell')
    newvalue('cmd')
    newvalue('PowerShell')
    newvalue('Bash')
    newvalue('Git')
    newvalue('Telnet')
    newvalue('Custom')
    defaultto('cmd')
  end

  newparam(:group_type) do
    desc 'The group_type setting. Valid options are: everyone, local, domain. Note: There can only be one group with group_type of everything.'

    validate do |value|
      unless ['everyone', 'local', 'domain'].include? value
        raise ArgumentError, 'group_type must be everyone, local, or domain'
      end
    end
  end

  newparam(:domain) do
    desc 'The domain to be used for domain groups.'

    validate do |value|
      raise ArgumentError, "Value must be a String'" unless value.is_a?(String)
    end
  end

  newproperty(:logon_type) do
    desc 'Logon type. Valid values are: interactive, network, bash. Default is: network.'

    newvalue('interactive')
    newvalue('network')
    newvalue('bash')
    defaultto('network')
  end

  newproperty(:on_account_info_failure) do
    desc 'on_account_info_failure. Valid values are: deny login, restrict access, disable profile, no restrictions. Default is: restrict access.'

    newvalue('deny login')
    newvalue('restrict access')
    newvalue('disable profile')
    newvalue('no restrictions')
    defaultto('restrict access')
  end

  newproperty(:max_wait_time) do
    desc 'max_wait_time. Valid values are: any integer. Default is: 300.'

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

    newvalues(:true, :false)

    defaultto(:true)
  end

  newproperty(:allow_agent_fwd_cygwin) do
    desc 'The allow_agent_fwd_cygwin setting. Valid values: true, false. Default: true'

    newvalues(:true, :false)

    defaultto(:true)
  end

  newproperty(:allow_agent_fqd_putty) do
    desc 'The allow_agent_fqd_putty setting. Valid values: true, false. Default: true'

    newvalues(:true, :false)

    defaultto(:true)
  end

  newproperty(:load_profile_for_file_xfer) do
    desc 'The load_profile_for_file_xfer setting. Valid values: true, false. Default: false'

    newvalues(:true, :false)

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
    desc 'The sfs_home_dir setting. Default: /%HOME%'

    validate do |value|
      raise ArgumentError, "Value must be a String'" unless value.is_a?(String)
    end

    defaultto('/%HOME%')
  end

  newproperty(:mounts, array_matching: :all) do
    desc 'The mount points for the group.'

    # validate do |value|
    #   raise ArgumentError, 'Value must be an Array' unless value.is_a?(Array)
    # end
    def insync?(is)
      # 'is' true/false values come back as a symbol (:true/:false)
      # convert them to true/false to we can compare with should values
      i = is
      i.each do |item|
        item.keys.each do |key|
          if item[key] == :true
            item[key] = true
          elsif item[key] == :false
            item[key] = false
          end
        end
      end
      i.sort_by { |k, _v| k['sfsMoutPath'] } == should.sort_by { |k, _v| k['sfsMoutPath'] }
    end
  end

  newproperty(:listen_rules, array_matching: :all) do
    desc 'The listen rules for the group.'

    # validate do |value|
    #   raise ArgumentError, 'Value must be an Array' unless value.is_a?(Array)
    # end
  end
end
