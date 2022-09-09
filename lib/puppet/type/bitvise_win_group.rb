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

  newproperty(:login_allowed) do
    desc 'The login_allowed setting'

    newvalue(0)
    newvalue(1)
    defaultto(0)

    validate do |value|
      raise Puppet::Error, _('must be a number') unless value.is_a?(Integer)
      super(value)
    end

    # override default munging of newvalue() to symbol, treating input as number
    munge { |value| value }
  end

  newproperty(:shell_access_type) do
    desc 'The shell_access_type setting'

    newvalue(0)
    newvalue(1)
    newvalue(2)
    newvalue(3)
    newvalue(4)
    defaultto(3)

    validate do |value|
      raise Puppet::Error, _('must be a number') unless value.is_a?(Integer)
      super(value)
    end

    # override default munging of newvalue() to symbol, treating input as number
    munge { |value| value }
  end
end
