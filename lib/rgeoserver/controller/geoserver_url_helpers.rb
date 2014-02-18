
module RGeoServer
  # Build URIs for GeoServer REST API
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
      %w{services wcs workspaces settings},
      %w{services wfs workspaces settings},
      %w{services wms workspaces settings},
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
    
    # Valid URI values for REST API
    URI_REGEX_VALUES = [
      { :about => /^(manifest|version)$/ },
      { :settings => /^(|contact)$/ },
      { :fonts => /^$/ },
      { :reload => /^$/ },
      { :reset => /^$/ },
      { :templates => /^(|.+\.ftl)$/ },
      { :services => /^$/, :wcs => /^$/, :settings => /^$/ },
      { :services => /^$/, :wfs => /^$/, :settings => /^$/ },
      { :services => /^$/, :wms => /^$/, :settings => /^$/ },
      { :services => /^$/, :wcs => /^$/, :workspaces => /.+/, :settings => /^$/ },
      { :services => /^$/, :wfs => /^$/, :workspaces => /.+/, :settings => /^$/ },
      { :services => /^$/, :wms => /^$/, :workspaces => /.+/, :settings => /^$/ },
      { :workspaces => /.+/, :datastores => /^.*$/ },
      { :workspaces => /.+/, :datastores => /.+/, :featuretypes => /^.*$/ },
      { :workspaces => /.+/, :datastores => /.+/, :file => /^$/ },
      { :workspaces => /.+/, :datastores => /.+/, :external => /^$/ },
      { :workspaces => /.+/, :datastores => /.+/, :url => /^$/ },
      { :workspaces => /.+/, :coveragestores => /.+/, :file => /^$/ },
      { :workspaces => /.+/, :coveragestores => /.+/, :coverages => /^.*$/ },
      { :workspaces => /.+/, :settings => /^$/ }
    ]

    # Valid formats for REST API
    # See http://docs.geoserver.org/stable/en/user/rest/api/details.html
    # URI_FORMATS = %w{xml json html sld zip}.map(&:to_sym)
    
    public
    # @see http://docs.geoserver.org/latest/en/user/rest/api/
    # @param [Hash] base for example:
    #   - { :settings => nil }
    #   - { :layers => name }
    #   - { :styles => name }
    #   - { :workspaces => nil }
    #   - { :workspaces => name }
    #   - { :workspaces => name, :datastores => nil }
    #   - { :workspaces => name, :datastores => name, :featuretype => nil }
    #   - { :workspaces => name, :datastores => name, :featuretype => name }
    # @param [Hash] options for query string
    # @return [String] baseURL for REST API, e.g.,:
    #   - settings
    #   - layers/_name_
    #   - styles/_name_
    #   - workspaces
    #   - workspaces/_name_
    #   - workspaces/_name_/datastores
    #   - workspaces/_name_/datastores/_name_/featuretype
    #   - workspaces/_name_/datastores/_name_/featuretype/_name_
    def url_for base, options = {}
      raise RGeoServer::ArgumentError, 'base must be Hash' unless base.is_a? Hash and not base.empty?
      raise RGeoServer::ArgumentError, 'options must be Hash' unless options.is_a? Hash

      # convert all keys to symbols
      base = Hash[base.map {|k,v| [k.to_sym, v]}]

      # verify that all paths are correct
      if URI_SEQUENCES.select {|k| k == base.keys }.empty?
        raise RGeoServer::ArgumentError, "Invalid REST URI syntax: #{base}" 
      end

      # preceeding arguments (all but last) cannot be nil
      if base.size > 1 and base.values.take(base.size - 1).map(&:nil?).any?
        raise RGeoServer::ArgumentError, "Preceeding arguments cannot be nil: #{base}"
      end
      
      # validate values using regular expressions
      URI_REGEX_VALUES.each do |h|
        if h.keys == base.keys
          h.each do |k, regex|
            raise RGeoServer::ArgumentError, "Invalid value: #{k} => #{base[k]}" unless regex.match(base[k].to_s)
          end
        end
      end

      # rebuild the base
      new_base = base.collect {|k,v| (v.nil? or v.empty?)? "#{k}" : "#{k}/#{v}"}.join('/').to_s
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