
module RGeoServer
  # A data store is a source of spatial data that is vector based. It can be a file in the case of a Shapefile, a database in the case of PostGIS, or a server in the case of a remote Web Feature Service.
  class DataStore < ResourceInfo
    attr_reader :workspace

    # attr_accessors
    # @see http://geoserver.org/display/GEOS/Catalog+Design
    OBJ_ATTRIBUTES = %w{
      name 
      connectionParameters
      description 
      enabled 
      type 
    }
    OBJ_DEFAULT_ATTRIBUTES = {
      :type => :shapefile,
      :enabled => true
    }  
    
    define_attribute_methods OBJ_ATTRIBUTES
    update_attribute_accessors OBJ_ATTRIBUTES

    # @return [Hash]
    def route
      { :workspaces => workspace.name, :datastores => name }
    end
    
    # @return [String]
    def to_s
      "#{self.class}: #{workspace.name}:#{@name} (new? #{new?})"
    end

    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options 
    # @option options [String | RGeoServer::Workspace] :workspace
    # @option options [String] :name
    # @return [RGeoServer::DataStore]
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
      
        raise RGeoServer::ArgumentError, "#{self.class}.new requires :name option" unless options.include?(:name)
        @name = options[:name].to_s.strip
      end
    end

    # @yield [RGeoServer::FeatureType]
    def featuretypes
      data = ActiveSupport::JSON.decode(catalog.search :workspaces => workspace.name, 
                                                       :datastores => name, 
                                                       :featuretypes => nil)
      data['featureTypes']['featureType'].each do |h| 
        yield get_featuretype(h['name'].to_s.strip)
      end
      nil
    end

    # @param [String] name
    # @return [RGeoServer::FeatureType]
    def get_featuretype name
      FeatureType.new catalog, :workspace => workspace, :datastore => self, :name => name
    end

    def message
      h = { :dataStore => { } }
      OBJ_ATTRIBUTES.each do |k|
        h[:dataStore][k.to_sym] = self.send k.to_sym
      end
      h.to_json
    end
    
    def profile_json_to_hash json
      ActiveSupport::JSON.decode(json)['dataStore']
    end
  end
end
