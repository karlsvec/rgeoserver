
module RGeoServer
  module GeoServerUrlHelpers
    
    # Valid base components for REST API
    @@URI_BASES = %w{
      coverages 
      coveragestores
      datastores 
      featuretypes
      file
      fonts
      external
      layergroups
      layers 
      namespaces
      settings 
      styles
      templates
      workspaces
      url
    }.map(&:to_sym)
    
    @@URI_FORMATS = %w{xml json html sld zip}.map(&:to_sym)
    
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
      raise ArgumentError, "options must be Hash" unless options.is_a? Hash
      base = { base.to_sym => nil } if base.is_a? String
      
      
      base = Hash[base.map {|k,v| [k.to_sym, v]}] unless base.keys.select {|k| not k.is_a? Symbol}.size == 0
      
      format = (options.delete(:format) if options.include?(:format)) || :xml
      raise ArgumentError, "Unknown REST API format: '#{format}'" unless @@URI_FORMATS.include?(format)
      
      base.keys.each do |k|
        raise ArgumentError, "Unknown REST API component: '#{k}' #{k.class}" unless @@URI_BASES.include?(k)
      end
      
      # implement rules for ordering
      if base.include?(:datastores) and not base[:workspaces]
        raise ArgumentError, "DataStore requires a Workspace"
      end
      if base[:layers] and base.include?(:workspaces)
        raise ArgumentError, "Layers cannot have a Workspace"
      end
      
      if base.include?(:featuretypes) and not base[:workspaces] and not base[:datastores]
        raise ArgumentError, "FeatureType requires a Workspace and DataStore"
      end

      if base.include?(:coverages) and not base[:workspaces] and not base[:coveragestores]
        raise ArgumentError, "Coverage requires a Workspace and CoverageStore"
      end

      new_base = base.collect {|k,v| v.nil?? "#{k}" : "#{k}/#{v}"}.join('/')
      new_base = new_base.gsub(/\/$/,'')
      new_base += ".#{format}"
      if not options.empty?
        new_base += "?" + CGI::escape(options.collect {|k,v| "#{k}=#{v}"}.join('&'))
      end
      
      new_base
    end

  end
end
