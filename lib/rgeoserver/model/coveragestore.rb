
module RGeoServer
  # A coverage store is a source of spatial data that is raster based.
  class CoverageStore < ResourceInfo
    attr_reader :workspace
    # attr_accessors
    # @see http://geoserver.org/display/GEOS/Catalog+Design
    OBJ_ATTRIBUTES = %w{
      name 
      connectionParameters
      enabled 
      type
      url 
    }
    OBJ_DEFAULT_ATTRIBUTES = {
      :type => :GeoTIFF,
      :enabled => true
    }  
    define_attribute_methods OBJ_ATTRIBUTES
    update_attribute_accessors OBJ_ATTRIBUTES
    
    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
    # @option options [Workspace|String] :workspace
    # @option options [String] :name
    # @raise [RGeoServer::ArgumentError] 
    def initialize catalog, options 
      super(catalog)
      run_callbacks :initialize do
        raise RGeoServer::ArgumentError, "#{self.class}.new requires :workspace option" unless options.include?(:workspace)
        ws = options[:workspace]
        if ws.instance_of? String
          @workspace = catalog.get_workspace(ws)
        elsif ws.instance_of? Workspace
          @workspace = ws
        else
          raise RGeoServer::ArgumentError, "Not a valid workspace: #{workspace}"
        end
    
        raise RGeoServer::ArgumentError, "#{self.class}.new requires :name option" unless options.include?(:name)
        @name = options[:name].to_s.strip
      end
    end

    # @yield [RGeoServer::Coverage]
    def coverages
      data = ActiveSupport::JSON.decode(catalog.search :workspaces => workspace.name, 
                                                       :coveragestores => name, 
                                                       :coverages => nil)
      data['coverages']['coverage'].each do |h| 
        yield get_coverage(h['name'].to_s.strip)
      end
      nil
    end

    # @param [String] name
    # @return [RGeoServer::Coverage]
    def get_coverage name
      Coverage.new catalog, :workspace => workspace, :coveragestore => self, :name => name
    end

    # @return [Hash]
    def route
      { :workspaces => workspace.name, :coveragestores => name }
    end
    
    # @return [String]
    def to_s
      "#{self.class}: #{workspace.name}:#{@name} (new? #{new?})"
    end

    def message
      h = { :coverageStore => { } }
      OBJ_ATTRIBUTES.each do |k|
        h[:coverageStore][k.to_sym] = self.send k
      end
      h.to_json
    end
    
    def profile_json_to_hash json
      ActiveSupport::JSON.decode(json)['coverageStore']
    end

  end
end 
