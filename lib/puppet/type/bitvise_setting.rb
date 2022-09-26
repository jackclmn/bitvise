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

  newproperty(:client_versions, array_matching: :all) do
    desc 'The client versions settings.'

    # validate do |value|
    #   raise ArgumentError, "Value must be an Array'" unless value.is_a?(Array)
    # end
    def insync?(is)
      s = should
      s.each do |item|
        item.keys.each do |key|
          item[key] = item[key].to_s
        end
      end
      is.sort_by { |k, _v| k['pattern'] } == s.sort_by { |k, _v| k['pattern'] }
    end
  end
end
