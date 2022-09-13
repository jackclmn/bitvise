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

  newparam(:type) do
    desc 'The name of the windows group.'

    newvalue('windows')
    newvalue('virtual')
    defaultto('windows')
  end

  newproperty(:login_allowed) do
    desc 'The login_allowed setting'

    newvalue(false)
    newvalue(true)
    defaultto(false) # TODO: does this need to be :false :true ?
    munge do |value|
      # convert the boolean above to integer
      types = {
        false => 0,
          true => 1
      }
      types[value]
    end
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

    munge do |value|
      # convert the string above to integer
      types = {
        'default' => 1,
          'none'       => 2,
          'BvShell'    => 10,
          'cmd'        => 3,
          'PowerShell' => 4,
          'Bash'       => 5,
          'Git'        => 6,
          'Telnet'     => 9,
          'Custom'     => 7
      }
      types[value]
    end
  end
end
