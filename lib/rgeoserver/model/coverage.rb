
module RGeoServer
  # A coverage is a raster based data set which originates from a coverage store.
  class Coverage < ResourceInfo
    attr_reader :workspace, :coveragestore

    # attr_accessors
    # @see http://geoserver.org/display/GEOS/Catalog+Design
    # uses 'description' rather than 'abstract' in the GeoServer Web admin UI
    OBJ_ATTRIBUTES = %w{
      name 
      defaultInterpolationMethod
      description 
      dimensions
      enabled 
      grid
      interpolationMethods
      keywords 
      latLonBoundingBox 
      metadata 
      namespace 
      nativeBoundingBox 
      nativeCRS 
      nativeFormat
      nativeName
      requestSRS
      responseSRS
      srs 
      supportedFormats
      title
      }
    OBJ_DEFAULT_ATTRIBUTES = { }
   
    # @see http://inspire.ec.europa.eu/schemas/common/1.0/common.xsd
    METADATA_TYPES = {
      'ISO19139' => 'application/vnd.iso.19139+xml',
      'TC211' => 'application/vnd.iso.19139+xml'
    }
   
    define_attribute_methods OBJ_ATTRIBUTES
    update_attribute_accessors OBJ_ATTRIBUTES

    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
    # @option options [Workspace|String] :workspace
    # @option options [CoverageStore|String] :coverage_store 
    # @option options [String] :name 
    # @raise [RGeoServer::ArgumentError]
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
      
        raise RGeoServer::ArgumentError, "#{self.class}.new requires :coveragestore option" unless options.include?(:coveragestore)
        cs = options[:coveragestore]
        if cs.instance_of? String
          @coveragestore = workspace.get_coveragestore(cs)
        elsif cs.instance_of? RGeoServer::CoverageStore
          @coveragestore = cs
        else
          raise RGeoServer::ArgumentError, "Not a valid coveragestore: #{cs}"
        end

        raise RGeoServer::ArgumentError, "#{self.class}.new requires :name option" unless options.include?(:name)
        @name = options[:name].to_s.strip
      end
    end


    # @return [Hash]
    def route
      { :workspaces => workspace.name, :coveragestores => coveragestore.name, :coverages => name }
    end
    
    # @return [String]
    def to_s
      "#{self.class}: #{workspace.name}:#{coveragestore.name}:#{@name} (new? #{new?})"
    end

    def message
      h = { :coverage => { } }
      OBJ_ATTRIBUTES.each do |k|
        h[:coverage][k.to_sym] = self.send k
      end
      h.to_json
    end
    
    def profile_json_to_hash json
      ActiveSupport::JSON.decode(json)['coverage']
    end

  end
end 
