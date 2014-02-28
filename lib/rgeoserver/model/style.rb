
module RGeoServer
  # A style describes how a resource (feature type or coverage) should be symbolized or rendered by a Web Map Service. In GeoServer styles are specified with {SLD}[http://docr.geoserver.org/stable/en/user/styling/index.html#styling]
  class Style < ResourceInfo
    
    # attr_accessors
    # @see http://geoserver.org/display/GEOS/Catalog+Design
    OBJ_ATTRIBUTES = %w{name filename sld_version sld_doc abstract title}
    OBJ_DEFAULT_ATTRIBUTES = {}

    define_attribute_methods OBJ_ATTRIBUTES
    update_attribute_accessors OBJ_ATTRIBUTES

    # 
    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
    def initialize catalog, options
      super(catalog)
      run_callbacks :initialize do
        raise RGeoServer::ArgumentError, "#{self.class}.new requires :name option" unless options.include?(:name)
        @name = options[:name].to_s.strip
      end
    end

  end
end 
