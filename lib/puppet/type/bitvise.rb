Puppet::Type.newtype(:bitvise) do
    @doc = <<-PUPPET
          @summary
          Manages bitvise configurations.
          PUPPET
  
    ensurable
  
    newparam(:name) do
      desc 'The name assigned to the bitvise instance.'
  
      isnamevar
    end
  
    newproperty(:trusted_lsp_only) do
      desc 'The trustedLspOnly setting'

      newvalue(0)
      newvalue(1)
      defaultto(1)

      validate do |value|
        raise Puppet::Error, _('must be a number') unless value.is_a?(Integer)
        super(value)
      end
  
      # override default munging of newvalue() to symbol, treating input as number
      munge { |value| value }
    end
end
