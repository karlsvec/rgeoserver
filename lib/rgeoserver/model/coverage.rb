
module RGeoServer
  # A coverage is a raster based data set which originates from a coverage store.
  class Coverage < ResourceInfo

    # attr_accessors
    # @see http://geoserver.org/display/GEOS/Catalog+Design
    OBJ_ATTRIBUTES = {
      :catalog => "catalog", 
      :workspace => "workspace", 
      :coverage_store => "coverage_store", 
      :enabled => "enabled",
      :name => "name", 
      :title => "title", 
      :abstract => "abstract", 
      :keywords => "keywords", 
      :metadata => "metadata", 
      :metadata_links => "metadataLinks" 
    }
    OBJ_DEFAULT_ATTRIBUTES = {
      :catalog => nil, 
      :workspace => nil, 
      :coverage_store => nil, 
      :enabled => "true",
      :name => nil, 
      :title => nil, 
      :abstract => nil,  
      :keywords => [],  
      :metadata => {},  
      :metadata_links => [] 
    } 
   
    # @see http://inspire.ec.europa.eu/schemas/common/1.0/common.xsd
    METADATA_TYPES = {
      'ISO19139' => 'application/vnd.iso.19139+xml',
      'TC211' => 'application/vnd.iso.19139+xml'
    }
   
    define_attribute_methods OBJ_ATTRIBUTES.keys
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
        elsif ws.instance_of? Workspace
          @workspace = ws
        else
          raise RGeoServer::ArgumentError, "Not a valid workspace: #{ws}"
        end
      
        raise RGeoServer::ArgumentError, "#{self.class}.new requires :coveragestore option" unless options.include?(:coveragestore)
        cs = options[:coveragestore]
        if cs.instance_of? String
          @coverage_store = workspace.get_coveragestore(cs)
        elsif cs.instance_of? CoverageStore
          @coverage_store = cs
        else
          raise RGeoServer::ArgumentError, "Not a valid coveragestore: #{cs}"
        end

        raise RGeoServer::ArgumentError, "#{self.class}.new requires :name option" unless options.include?(:name)
        @name = options[:name].to_s.strip
      end
    end

    protected
    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.coverage {
          xml.name name
          xml.title title 
          xml.enabled enabled if enabled_changed? or new?
          if new?
            xml.nativeName name
            xml.abstract abstract if abstract_changed?
            xml.metadataLinks {
              metadata_links.each do |m|
                xml.metadataLink {
                  xml.type_ to_mimetype(m['metadataType'])
                  xml.metadataType m['metadataType']
                  xml.content m['content']
                }
              end
            } if metadata_links
          end
          xml.keywords {
            keywords.each do |k|
              xml.keyword RGeoServer::Metadata::to_keyword(k)
            end
          } if keywords and new? or keywords_changed?
          
        }
      end
      message = builder.doc.to_xml 
    end

    # @return [Hash] extraction from GeoServer XML for this coverage
    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml
      {
        "coverage_store" => coverage_store.name,
        "workspace" => workspace.name,
        "name" => doc.at_xpath('//name').text.strip,
        "nativeName" => doc.at_xpath('//nativeName').text,
        "nativeCRS" => doc.at_xpath('//nativeCRS').text,
        "title" => doc.at_xpath('//title').text,
        "srs" => doc.at_xpath('//srs').text,
        "nativeBoundingBox" => { 
          'minx' => doc.at_xpath('//nativeBoundingBox/minx').text.to_f,
          'miny' => doc.at_xpath('//nativeBoundingBox/miny').text.to_f,
          'maxx' => doc.at_xpath('//nativeBoundingBox/maxx').text.to_f,
          'maxy' => doc.at_xpath('//nativeBoundingBox/maxy').text.to_f,
          'crs' => doc.at_xpath('//nativeBoundingBox/crs').text
        },
        "latLonBoundingBox" => { 
          'minx' => doc.at_xpath('//latLonBoundingBox/minx').text.to_f,
          'miny' => doc.at_xpath('//latLonBoundingBox/miny').text.to_f,
          'maxx' => doc.at_xpath('//latLonBoundingBox/maxx').text.to_f,
          'maxy' => doc.at_xpath('//latLonBoundingBox/maxy').text.to_f,
          'crs' => doc.at_xpath('//latLonBoundingBox/crs').text
        },
        "abstract" => doc.at_xpath('//abstract').text, 
        "supportedFormats" => doc.xpath('//supportedFormats/string').collect{ |t| t.to_s },
        "keywords" => doc.at_xpath('//keywords').collect { |kl|
          {
            'keyword' => kl.at_xpath('//string').text
          }
        },
        "metadataLinks" => doc.xpath('//metadataLinks/metadataLink').collect{ |m|
          {
            'type' => m.at_xpath('//type').text,
            'metadataType' => m.at_xpath('//metadataType').text,
            'content' => m.at_xpath('//content').text
          }
        },
      }.freeze
    end

    def to_mimetype(type, default = 'text/xml')
      return METADATA_TYPES[type.upcase] if METADATA_TYPES.include?(type.upcase) 
      default
    end

  end
end 
