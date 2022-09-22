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

  ensurable

  newparam(:name) do
    desc 'The name of the bitvise instance.'

    isnamevar
  end

  newparam(:bsscfg) do
    desc 'The name of the com object for your version.'
  end

  newproperty(:send_fwding_rule_descs) do
    desc 'Valid values: true, false. Defaults to false'
    newvalue(:false)
    newvalue(:true)
    munge { |value| value }
  end

  newproperty(:log_file_rollover_by_size) do
    desc 'Valid values: true, false. Defaults to false'
    newvalue(:false)
    newvalue(:true)
  end

  newproperty(:ssh_dss) do
    desc 'Valid values: true, false. Defaults to false'
    newvalue(:false)
    newvalue(:true)
  end

  newproperty(:alg_3des_ctr) do
    desc 'Valid values: true, false. Defaults to false'
    newvalue(:false)
    newvalue(:true)
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
