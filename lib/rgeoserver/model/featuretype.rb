
module RGeoServer
  # A feature type is a vector based spatial resource or data set that originates from a data store.
  # In some cases, like Shapefile, a feature type has a one-to-one relationship with its data store.
  # In other cases, like PostGIS, the relationship of feature type to data store is many-to-one, with
  # each feature type corresponding to a table in the database.
  class FeatureType < ResourceInfo
    attr_reader :workspace, :datastore
      
    # attr_accessors
    # @see http://geoserver.org/display/GEOS/Catalog+Design  
    OBJ_ATTRIBUTES = %w{
      name 
      abstract 
      advertised
      enabled 
      keywords 
      latLonBoundingBox 
      metadataLinks 
      namespace 
      nativeBoundingBox 
      nativeCRS 
      nativeName 
      projectionPolicy 
      srs 
      title 
      }
    OBJ_DEFAULT_ATTRIBUTES = {
      :projection_policy => :keep
    }

    define_attribute_methods OBJ_ATTRIBUTES
    update_attribute_accessors OBJ_ATTRIBUTES

    # @see http://inspire.ec.europa.eu/schemas/common/1.0/common.xsd
    METADATA_TYPES = {
      'ISO19139' => 'text/xml',
      'TC211' => 'text/xml'
    }
    
    # @see https://github.com/geoserver/geoserver/blob/master/src/main/src/main/java/org/geoserver/catalog/ProjectionPolicy.java
    PROJECTION_POLICIES = {
      :force => 'FORCE_DECLARED',
      :reproject => 'REPROJECT_TO_DECLARED',
      :keep => 'NONE'
    }
    
    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
    def initialize catalog, options
      super(catalog)
      run_callbacks :initialize do
        raise RGeoServer::ArgumentError, "#{self.class}.new requires :workspace option" unless options.include?(:workspace)
        ws = options[:workspace]
        if ws.instance_of? String
          @workspace = catalog.get_workspace(ws)
        elsif ws.instance_of? RGeoServer::Workspace
          @workspace = ws
        else
          raise RGeoServer::ArgumentError, "Not a valid workspace: #{ws}"
        end
      
        raise RGeoServer::ArgumentError, "#{self.class}.new requires :datastore option" unless options.include?(:datastore)
        ds = options[:datastore]
        if ds.instance_of? String
          @datastore = workspace.get_datastore(ds)
        elsif ds.instance_of? RGeoServer::DataStore
          @datastore = ds
        else
          raise RGeoServer::ArgumentError, "Not a valid datastore: #{ds}"
        end

        raise RGeoServer::ArgumentError, "#{self.class}.new requires :name option" unless options.include?(:name)
        @name = options[:name].to_s.strip
      end
    end

    # @return [String]
    def to_s
      "#{self.class}: #{workspace.name}:#{datastore.name}:#{@name} (new? #{new?})"
    end

    def message
      h = { :featureType => { } }
      OBJ_ATTRIBUTES.each do |k|
        h[:featureType][k.to_sym] = self.send k.to_sym
      end
      h.to_json
    end

    protected
    # @return [OrderedHash]
    def route
      { :workspaces => workspace.name, :datastores => datastore.name, :featuretypes => name }
    end

    def to_mimetype(type, default = 'text/xml')
      k = type.to_s.strip.upcase
      return METADATA_TYPES[k] if METADATA_TYPES.include? k
      default
    end
    
    
    def profile_json_to_hash json
      ActiveSupport::JSON.decode(json)['featureType']
    end
    
    private
    def valid_native_bounds?
      bbox = RGeoServer::BoundingBox.new(native_bounds)
      not bbox.nil? and bbox.valid? and not native_bounds['crs'].empty?
    end

    def valid_latlon_bounds?
      bbox = RGeoServer::BoundingBox.new(latlon_bounds)
      not bbox.nil? and bbox.valid? and not latlon_bounds['crs'].empty?
    end
    
    def get_projection_policy_sym value
      v = value.strip.upcase
      if PROJECTION_POLICIES.has_value? v
        PROJECTION_POLICIES.invert[v]
      else
        raise RGeoServer::ArgumentError, "Invalid PROJECTION_POLICY: #{v}"
      end
    end

    def get_projection_policy_message value
      k = value
      k = k.strip.to_sym if not k.is_a? Symbol
      if PROJECTION_POLICIES.has_key? k
        PROJECTION_POLICIES[k]
      else
        raise RGeoServer::ArgumentError, "Invalid PROJECTION_POLICY: #{k}"
      end
    end
  end
end
