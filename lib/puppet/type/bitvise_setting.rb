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
      Puppet.debug("is: #{is}")
      Puppet.debug("i: #{i}")
      Puppet.debug("should: #{should}")
      i.sort_by { |k, _v| k['pattern'] } == should.sort_by { |k, _v| k['pattern'] }
    end
  end
end
