module RGeoServer
  # A workspace is a grouping of data stores. More commonly known as a namespace, 
  # it is commonly used to group data that is related in some way.
  class Workspace < ResourceInfo
    # attr_accessors
    # @see http://geoserver.org/display/GEOS/Catalog+Design
    OBJ_ATTRIBUTES = %w{name enabled}
    OBJ_DEFAULT_ATTRIBUTES = {
      :enabled => 'true'
    }

    define_attribute_methods OBJ_ATTRIBUTES
    update_attribute_accessors OBJ_ATTRIBUTES

    # @param [RGeoServer::Catalog] catalog
    # @option options [String] :name
    # @return [RGeoServer::Workspace]
    def initialize catalog, options
      super(catalog)
      run_callbacks :initialize do
        raise RGeoServer::ArgumentError, "#{self.class}.new requires :name option" unless options.include?(:name)
        @name = options[:name].to_s.strip
      end
    end

    # @return [OrderedHash]
    def route
      { :workspaces => name }
    end
    
    # @return [String]
    def to_s
      "#{self.class}: #{@name} (new? #{new?})"
    end
    
    #= Data Stores (Vector datasets)

    # @yield [RGeoServer::DataStore]
    def datastores
      data = JSON.decode(catalog.search :workspaces => name, :datastores => nil)
      data['dataStores']['dataStore'].each do |h|
        yield get_datastore(h['name'].to_s.strip)
      end
      nil
    end

    # @param [String] name
    # @return [RGeoServer::DataStore]
    def get_datastore name
      DataStore.new catalog, :workspace => self, :name => name
    end

    #= Coverages (Raster datasets)

    # @param [String] workspace
    # @yield [RGeoServer::CoverageStore]
    def coveragestores 
      data = JSON.decode(catalog.search :workspaces => name, :coveragestores => nil)
      data['coverageStores']['coverageStore'].each do |h|
        yield get_coveragestore(h['name'].to_s.strip)
      end
      nil
    end

    # @param [String] name
    # @return [RGeoServer::CoverageStore]
    def get_coveragestore name
      CoverageStore.new catalog, :workspace => self, :name => name
    end
    
    # protected

    # @return [String] JSON document with workspace attributes
    def message
      h = { :workspace => { } }
      OBJ_ATTRIBUTES.each do |k|
        h[:workspace][k.to_sym] = self.send k.to_sym
      end
      h.to_json
    end

    def profile_json_to_hash json
      JSON.decode(json)['workspace']
    end
  end
end 
