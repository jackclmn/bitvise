#
Puppet::Type.newtype(:bitvise_account) do
  @doc = <<-PUPPET
              @summary
              Manages bitvise accounts.
              PUPPET

  ensurable

  newparam(:name) do
    desc 'The friendly name for this resource. This is the namevar for the resource but is not used.
          This allows multiple accouts to have the same name (one virtual account and one windows account)
          without a duplicate resource declaration. Use account_name to specify the name.'

    isnamevar
  end

  newparam(:account_name) do
    desc 'The name of the account to be created.'

    validate do |value|
      raise ArgumentError, "Value must be a String'" unless value.is_a?(String)
    end
  end

  newparam(:account_type) do
    desc 'The type of account to be created. Valid values: windows, virtual.'

    validate do |value|
      unless ['windows', 'virtual'].include? value
        raise ArgumentError, 'account_type must be windows or virtual'
      end
    end
  end

  newproperty(:specify_group) do
    desc 'Valid values: true, false.'

    newvalues(:true, :false)
  end

  newparam(:group_type) do
    desc 'Valid values: everyone, local, domain. This parameter applies when type is windows, not virtual.'

    validate do |value|
      unless ['everyone', 'local', 'domain'].include? value
        raise ArgumentError, 'group_type must be everyone, local, or domain'
      end
    end
  end

  newproperty(:group) do
    desc 'The name of the group for the account.'

    validate do |value|
      raise ArgumentError, "Value must be a String'" unless value.is_a?(String)
    end
  end

  newproperty(:win_account) do
    desc 'The name of the windows account used by the virtual account. This property only applies to virtual accounts.'

    validate do |value|
      raise ArgumentError, "Value must be a String'" unless value.is_a?(String)
    end
  end

  newproperty(:win_domain) do
    desc 'The name of the windows domain used by the virtual account. This property only applies to virtual accounts.'

    validate do |value|
      raise ArgumentError, "Value must be a String'" unless value.is_a?(String)
    end
  end

  newproperty(:security_context) do
    desc 'The security context. Valid values: default, auto, local, domain, service, microsoft.
      This setting only applies to virtual accounts.'

    newvalue('default')
    newvalue('auto')
    newvalue('local')
    newvalue('domain')
    newvalue('service')
    newvalue('microsoft')
  end

  newproperty(:login_allowed) do
    desc 'The login_allowed setting. Valid values: true, false.'

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

  newproperty(:keys, array_matching: :all) do
    desc 'The public keys to import.'

    # validate do |value|
    #   raise ArgumentError, "Value must be an Array'" unless value.is_a?(Array)
    # end
    def insync?(is)
      is.map { | k | k.gsub("\n",'')}
      is == should
    end
  end
end
