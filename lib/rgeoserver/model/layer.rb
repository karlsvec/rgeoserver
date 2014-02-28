
module RGeoServer
  # A layer is a published resource (feature type or coverage).
  class Layer < ResourceInfo

    # attr_accessors
    # @see http://geoserver.org/display/GEOS/Catalog+Design
    OBJ_ATTRIBUTES = %w{
      enabled
      queryable
      path
      name
      default_style
      alternative_styles
      metadata
      attribution
      type
    }
    OBJ_DEFAULT_ATTRIBUTES = {
      :enabled => 'true',
      :queryable => 'true',
      :path => '/',
      :alternate_styles => [],
      :metadata => {
        'GWC.autoCacheStyles' => 'true',
        'GWC.gutter' => '0',
        'GWC.enabled' => 'true',
        'GWC.cacheFormats' => 'image/jpeg,image/png',
        'GWC.gridSets' => 'EPSG:4326,EPSG:900913'
      },
      :attribution => {
        'logo_height' => '0',
        'logo_width' => '0',
        'title' => ''
      }
    }

    define_attribute_methods OBJ_ATTRIBUTES
    update_attribute_accessors OBJ_ATTRIBUTES

    # @return [OrderedHash]
    def route
      { :layers => name }
    end
    
    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
    # @option options [String] :name required
    # @option options [String] :default_style
    # @option options [Array<String>] :alternate_styles
    def initialize catalog, options
      super(catalog)
      run_callbacks :initialize do
        raise RGeoServer::ArgumentError, "#{self.class}.new requires :name option" unless options.include?(:name)
        if options[:name].instance_of? Layer
          @name = options[:name].name
        else
          @name = options[:name].to_s.strip
        end
      end
    end

    def styles
      raise NotImplementedError
    end
    
    def get_style name
      raise NotImplementedError
    end

    #= GeoWebCache Operations for this layer
    # See http://geowebcache.org/docs/current/rest/seed.html
    # See RGeoServer::Catalog.seed_terminate for stopping pending and/or running tasks for any layer
    #
    # Example:
    #  > lyr = RGeoServer::Layer.new catalog, :name => 'Arc_Sample'
    #  > options = {
    #    :srs => {:number => 4326 },
    #    :zoomStart => 1,
    #    :zoomStop => 12,
    #    :format => 'image/png',
    #    :threadCount => 1
    #  }
    #  > lyr.seed :issue, options
    #
    # @see http://geowebcache.org/docs/current/rest/
    # @param[String] operation
    # @option operation[Symbol] :issue seed
    # @option operation[Symbol] :truncate seed
    # @option operation[Symbol] :status of the seeding thread
    # @param[Hash] options for seed message. Read the documentation
    def seed op, options
      sub_path = "seed/#{resource.workspace.name}:#{@name}"
      case op
      when :issue
        catalog.do_url sub_path, _build_seed_request(:seed, options), :post, {}, catalog.gwc_client
      when :truncate
        catalog.do_url sub_path, _build_seed_request(:truncate, options), :post, {}, catalog.gwc_client
      when :status
        raise NotImplementedError, op.to_s
      else
        raise ArgumentError, "Unknown operation: #{op}"
      end
    end

    protected
    
    def resource= r
      unless r.is_a?(RGeoServer::Coverage) or r.is_a?(RGeoServer::FeatureType)
        raise RGeoServer::ArgumentError, "Unknown resource type: #{r.class}"
      end
      @resource = r
    end

    def resource
      @resource ||= begin
        h = profile['resource']
        raise ArgumentError, 'Missing resource' if h.nil? or h.empty?
        w = catalog.get_workspace(h['workspace'])
        case h['type'].downcase.to_sym
        when :coverage
          return w.get_coveragestore(h['store']).get_coverage(h['name'])
        when :featuretype
          return w.get_datastore(h['store']).get_featuretype(h['name'])
        else
          raise RGeoServer::ArgumentError, "Unknown resource type: #{h['type']}"
        end
      end
    end
    
    def message
      h = { :layer => { } }
      OBJ_ATTRIBUTES.each do |k|
        h[:layer][k.to_sym] = self.send k.to_sym
      end
      h.to_json
    end

    private
    # @param[Hash] options for seed message, requiring
    #  options[:srs][:number]
    #  options[:bounds][:coords]
    #  options[:gridSetId]
    #  options[:zoomStart]
    #  options[:zoomStop]
    #  options[:gridSetId]
    #  options[:gridSetId]
    #
    def _build_seed_request operation, options
      raise NotImplementedError
    end
  end

end
