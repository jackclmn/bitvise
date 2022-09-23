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
Puppet::Type.newtype(:bitvise_setting) do
  @doc = <<-PUPPET
                @summary
                Manages bitvise settings.
                PUPPET

  newparam(:name) do
    desc 'The resource name of the bitvise instance. This is the namevar for the resource but does not do anything.'

    isnamevar
  end

  newproperty(:send_fwding_rule_descs) do
    desc 'Valid values: true, false.'

    newvalues(:true, :false)
  end

  newproperty(:log_file_rollover_by_size) do
    desc 'Valid values: true, false.'

    newvalues(:true, :false)
  end

  newproperty(:ssh_dss) do
    desc 'Valid values: true, false.'

    newvalues(:true, :false)
  end

  newproperty(:alg_3des_ctr) do
    desc 'Valid values: true, false.'

    newvalues(:true, :false)
  end

  newproperty(:min_rsa_key_bits) do
    desc 'min_rsa_key_bits. Valid values are: any integer.'

    validate do |value|
      raise Puppet::Error, _('must be a number') unless value.is_a?(Integer)
      super(value)
    end

    # override default munging of newvalue() to symbol, treating input as number
    munge { |value| value }
  end

  newproperty(:min_dsa_key_bits) do
    desc 'min_dsa_key_bits. Valid values are: any integer.'

    validate do |value|
      raise Puppet::Error, _('must be a number') unless value.is_a?(Integer)
      super(value)
    end

    # override default munging of newvalue() to symbol, treating input as number
    munge { |value| value }
  end

  newproperty(:total_threshold) do
    desc 'total_threshold. Valid values are: any integer.'

    validate do |value|
      raise Puppet::Error, _('must be a number') unless value.is_a?(Integer)
      super(value)
    end

    # override default munging of newvalue() to symbol, treating input as number
    munge { |value| value }
  end

  newproperty(:lockout_mins) do
    desc 'lockout_mins. Valid values are: any integer.'

    validate do |value|
      raise Puppet::Error, _('must be a number') unless value.is_a?(Integer)
      super(value)
    end

    # override default munging of newvalue() to symbol, treating input as number
    munge { |value| value }
  end
end
