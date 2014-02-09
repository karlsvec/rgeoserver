
module RGeoServer
  module GeoServerUrlHelpers
    private
    # Valid URI sequences for REST API
    # @see http://docs.geoserver.org/stable/en/user/rest/index.html
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
      %w{reset}
    ].map {|x| x.map(&:to_sym)}
    
    # Regexp processing for #URI_SEQUENCES
    URI_REGEX_VALID = URI_SEQUENCES.map do |a|
      Regexp.new('^' + a.map {|x| x.to_s}.join('/\w+/') + '[/\w]*$')
    end
    URI_REGEX_VALID << %r/^about\/version$/
    URI_REGEX_VALID << %r/^about\/manifest$/
          
    URI_REGEX_INVALID = [ 
      %r/^layers\/styles$/,
      %r/^layers\/\w+\/styles\/\w+$/,
      %r/^workspaces\/\w+\/layers\/\w+$/,
      %r/^workspaces\/\w+\/coverages\/\w+$/,
      %r/^workspaces\/\w+\/coverages$/
    ]
    
    # Valid formats for REST API
    # See http://docs.geoserver.org/stable/en/user/rest/api/details.html
    URI_FORMATS = %w{xml json html sld zip}.map(&:to_sym)
    
    public
    # @see http://docs.geoserver.org/latest/en/user/rest/api/
    # @param [Hash] base examples:
    # - { :workspaces => nil }
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
      raise GeoServerArgumentError, 'base must be Hash' unless base.is_a? Hash
      raise GeoServerArgumentError, 'options must be Hash' unless options.is_a? Hash

      # convert all keys to symbols
      unless base.keys.select {|k| not k.is_a? Symbol}.size == 0
        base = Hash[base.map {|k,v| [k.to_sym, v]}] 
      end
      
      # preceeding arguments cannot be nil
      if base.to_a[0..-2].select{|x| x[1].nil?}.size > 0
        raise GeoServerArgumentError, 'Preceeding arguments cannot be nil'
      end
      
      # verify that format is ok
      format = (options.delete(:format) if options.include?(:format)) || :xml
      unless URI_FORMATS.include?(format)
        raise GeoServerArgumentError, "Unknown REST API format: '#{format}'" 
      end
      
      # rebuild the base
      new_base = base.collect {|k,v| v.nil?? "#{k}" : "#{k}/#{v}"}.join('/').to_s
      new_base = new_base.gsub(%r{/$}, '')
      
      # verify that all paths are correct
      unless URI_REGEX_VALID.each.select {|r| r.match(new_base)}.size > 0
        raise GeoServerArgumentError, "Invalid REST URI syntax: #{new_base} from #{base}" 
      end
      if URI_REGEX_INVALID.each.select {|r| r.match(new_base)}.size > 0
        raise GeoServerArgumentError, "Invalid REST URI syntax: #{new_base} from #{base}" 
      end
      
      # append format and options
      new_base += ".#{format}"
      unless options.empty?
        new_base += '?' + options.collect {|k,v| [CGI::escape(k.to_s), CGI::escape(v.to_s)].join('=')}.join('&')
      end
      
      puts "url_for: #{base} #{options} => #{new_base}" if $DEBUG
      new_base
    end
  end
end
