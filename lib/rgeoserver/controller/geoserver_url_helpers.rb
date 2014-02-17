require 'awesome_print'

module RGeoServer
  module GeoServerUrlHelpers
    private
    # Valid URI sequences for REST API
    # @see http://docs.geoserver.org/stable/en/user/rest/index.html
    URI_SEQUENCES = [
      %w{about},
      %w{fonts},
      %w{layergroups},
      %w{layers styles},
      %w{layers},
      %w{namespaces},
      %w{reload},
      %w{reset},
      %w{services wcs settings},
      %w{services wfs settings},
      %w{services wms settings},
      %w{settings contact},
      %w{settings},
      %w{styles},
      %w{templates},
      %w{workspaces coveragestores coverages},
      %w{workspaces coveragestores file},
      %w{workspaces coveragestores},
      %w{workspaces datastores external},
      %w{workspaces datastores featuretypes},
      %w{workspaces datastores file},
      %w{workspaces datastores url},
      %w{workspaces datastores},
      %w{workspaces layergroups},
      %w{workspaces settings},
      %w{workspaces styles},
      %w{workspaces}
    ].map {|x| x.map(&:to_sym)}

    # Valid formats for REST API
    # See http://docs.geoserver.org/stable/en/user/rest/api/details.html
    # URI_FORMATS = %w{xml json html sld zip}.map(&:to_sym)
    
    public
    # @see http://docs.geoserver.org/latest/en/user/rest/api/
    # @param [Hash] base examples:
    # - { :settings => nil }
    # - { :layers => name }
    # - { :styles => name }
    # - { :workspaces => nil }
    # - { :workspaces => name }
    # - { :workspaces => name, :datastores => nil }
    # - { :workspaces => name, :datastores => name, :featuretype => nil }
    # - { :workspaces => name, :datastores => name, :featuretype => name }
    # @param [Hash] options
    # @return [String] baseURL for REST API, e.g.,:
    # - settings
    # - layers/_name_
    # - styles/_name_
    # - workspaces
    # - workspaces/_name_
    # - workspaces/_name_/datastores
    # - workspaces/_name_/datastores/_name_/featuretype
    # - workspaces/_name_/datastores/_name_/featuretype/_name_
    def url_for base, options = {}
      raise GeoServerArgumentError, 'base must be Hash' unless base.is_a? Hash and not base.empty?
      raise GeoServerArgumentError, 'options must be Hash' unless options.is_a? Hash

      # convert all keys to symbols
      base = Hash[base.map {|k,v| [k.to_sym, v]}]
      
      # verify that all paths are correct
      if URI_SEQUENCES.select {|k| k == base.keys }.empty?
        raise GeoServerArgumentError, "Invalid REST URI syntax: #{base}" 
      end

      # preceeding arguments (all but last) cannot be nil
      if base.size > 1 and base.values.take(base.size - 1).map(&:nil?).any?
        raise GeoServerArgumentError, "Preceeding arguments cannot be nil: #{base}"
      end
            
      # rebuild the base
      new_base = base.collect {|k,v| v.nil?? "#{k}" : "#{k}/#{v}"}.join('/').to_s
      new_base = new_base.gsub(%r{/$}, '')
            
      # append options
      unless options.empty?
        new_base += '?' + options.collect {|k,v| [CGI::escape(k.to_s), CGI::escape(v.to_s)].join('=')}.join('&')
      end
      
      puts "url_for: #{base} #{options} => #{new_base}" if $DEBUG
      new_base
    end
  end
end
