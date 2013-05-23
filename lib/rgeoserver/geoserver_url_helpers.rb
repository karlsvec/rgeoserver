
module RGeoServer
  module GeoServerUrlHelpers
        
    # Valid URI sequences for REST API
    # See http://docs.geoserver.org/stable/en/user/rest/index.html
    URI_SEQUENCES = [
      %w{settings},
      %w{settings contact},
      %w{workspaces},
      %w{workspaces settings},
      %w{namespaces},
      %w{workspaces datastores},
      %w{workspaces datastores file},
      %w{workspaces datastores external},
      %w{workspaces datastores url},
      %w{workspaces datastores featuretypes},
      %w{workspaces coveragestores},
      %w{workspaces coveragestores file},
      %w{workspaces coveragestores coverages},
      %w{styles},
      %w{workspaces styles},
      %w{layers},
      %w{layers styles},
      %w{layergroups},
      %w{workspaces layergroups},
      %w{fonts},
      %w{templates},
      %w{services wcs settings},
      %w{services wfs settings},
      %w{services wms settings},
      %w{reload},
      %w{reset},
      %w{about}
    ].map {|x| x.map(&:to_sym)}
    
    # Regexp processing for #URI_SEQUENCES
    URI_REGEX = URI_SEQUENCES.map do |a|
      Regexp.new('^' + a.map {|x| x.to_s}.join('/\w+/') + '[/\w]*$')
    end
        
    # Valid formats for REST API
    # See http://docs.geoserver.org/stable/en/user/rest/api/details.html
    URI_FORMATS = %w{xml json html sld zip}.map(&:to_sym)
    
    # See http://docs.geoserver.org/latest/en/user/rest/api/
    # @param [Hash] base, examples:
    # - { :workspaces => nil }
    #
    # @param [Hash] options
    # @return [String] baseURL for REST API, e.g.,:
    # - settings.xml
    # - layers/_name_.xml
    # - styles/_name_.xml
    # - workspaces/_name_.xml
    # - workspaces/_name_/settings.xml
    # - namespaces/_name_.xml
    # - workspaces/_name_/datastores/_name_.xml
    # - workspaces/_name_/datastores/_name_/featuretype/_name_.xml
    def url_for base, options = {}
      raise GeoServerArgumentError, "options must be Hash" unless options.is_a? Hash
      if base.is_a? String
        $stderr.puts "WARNING: deprecated usage -- base should be Hash"
        base = { base.to_sym => nil } if base.is_a? String
      end

      base = Hash[base.map {|k,v| [k.to_sym, v]}] unless base.keys.select {|k| not k.is_a? Symbol}.size == 0
      
      format = (options.delete(:format) if options.include?(:format)) || :xml
      raise GeoServerArgumentError, "Unknown REST API format: '#{format}'" unless URI_FORMATS.include?(format)
      
      new_base = base.collect {|k,v| v.nil?? "#{k}" : "#{k}/#{v}"}.join('/').to_s
      new_base = new_base.gsub(%r{/$}, '')
      
      raise GeoServerArgumentError, "Invalid REST URI syntax: #{new_base}" unless URI_REGEX.each.select {|r| r.match(new_base)}.size > 0
      
      new_base += ".#{format}"
      if not options.empty?
        new_base += "?" + options.collect {|k,v| [CGI::escape(k.to_s), CGI::escape(v.to_s)].join('=')}.join('&')
      end
      ap "url_for: #{base} #{options} => #{new_base}" if $DEBUG
      new_base
    end
    
    # See http://docs.geoserver.org/latest/en/user/rest/api/
    # @param [Hash] sequence with values. Note that the sequence can end in a nil, but none of the preceding elements may be nil
    # - 'workspaces'
    # - { :workspaces => nil }
    # - { :workspaces => 'default', :datastores => nil }
    # - { :about => 'version' }
    #
    # @param [Hash] options :format. See `URI_FORMATS`
    #
    # @return [String] baseURL for REST API, e.g.,:
    # - workspaces.xml
    # - workspaces/_name_.json
    # - workspaces/_name_/datastores.xml
    # - workspaces/_name_/datastores/_name_/featuretype/_name_.xml
    #
    # @raise [GeoServerArgumentError] if sequence is invalid
    # def url_for_NOT_READY sequence, options = { }
    #   if sequence.is_a? Hash
    #     # ap "url_for(String): #{sequence}"
    #     new_base = sequence
    #   else
    #     # ap "url_for(Hash): #{sequence}"
    #     raise GeoServerArgumentError, "sequence must be Hash" unless sequence.is_a? Hash
    #     if sequence.keys.select {|k| k.is_a? Symbol}.empty?
    #       raise GeoServerArgumentError, "Sequence must use symbol keys: #{sequence}"
    #     end
    # 
    #     raise GeoServerArgumentError, "Invalid sequence: #{sequence}" unless URI_SEQUENCES.include?(sequence.keys.to_a)
    # 
    #     # sequence can end in a nil, but none of the preceding elements may
    #     if sequence.size > 1
    #       sequence.keys.slice(0..-2).reverse_each do |k|
    #         raise GeoServerArgumentError, "Missing required sequence value for #{k}: #{sequence}" if sequence[k] == nil
    #       end
    #     end
    # 
    #     # `about` sequence can only be :version or :manifest
    #     if sequence.include?(:about) and not [:manifest, :version].include?(sequence[:about])
    #       raise GeoServerArgumentError, "Missing required sequence symbol for about [:manifest, :version]: #{sequence}"
    #     end
    # 
    #     if sequence.keys == [:layers, :styles]
    #       raise GeoServerArgumentError, "Cannot retrieve specific layer style: #{sequence}" if sequence[:styles] != nil
    #     end
    # 
    #     raise GeoServerArgumentError, "options must be Hash: #{options}" unless options.is_a? Hash      
    #     format = options.delete(:format) || :xml
    #     raise GeoServerArgumentError, "Unknown REST API format: '#{format}'" unless URI_FORMATS.include?(format)
    # 
    #     new_base = sequence.collect {|k,v| v.nil?? "#{k}" : "#{k}/#{v}"}.join('/')
    #   end
    #   
    #   raise TypeError if new_base.is_a? String if $DEBUG
    #   
    #   new_base = new_base.gsub(/\/$/,'')
    #   new_base += ".#{format}"
    #   if not options.empty?
    #     new_base += "?" + CGI::escape(options.collect {|k,v| "#{k}=#{v}"}.join('&'))
    #   end
    #   new_base
    # end
  end
end
