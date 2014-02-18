
module RGeoServer
  # A coverage store is a source of spatial data that is raster based.
  class CoverageStore < ResourceInfo

    OBJ_ATTRIBUTES = {
      :catalog => 'catalog', 
      :workspace => 'workspace', 
      :url => 'url', 
      :data_type => 'type', 
      :name => 'name', 
      :enabled => 'enabled', 
      :description => 'description'
    }  
    OBJ_DEFAULT_ATTRIBUTES = {
      :catalog => nil, 
      :workspace => nil, 
      :url => '', 
      :data_type => 'GeoTIFF', 
      :name => nil, 
      :enabled => 'true', 
      :description=>nil
    }  
    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES
    
    def update_params name_route = @name 
      { :name => name_route, :workspace => workspace.name }
    end

    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.coverageStore {
          xml.name name  
          xml.workspace {
            xml.name workspace.name
          }
          xml.enabled enabled if enabled_changed? or new?
          xml.type_ data_type if data_type_changed? or new?
          xml.description description if description_changed? or new?
          xml.url url if url_changed? or new?
        }
      end
      message = builder.doc.to_xml 
    end

    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
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

    # @param [String] workspace
    # @yield [RGeoServer::Coverage]
    def coverages
      doc = Nokogiri::XML(search :workspaces => workspace.name, :coveragestores => name, :coverages => nil)
      doc.xpath('/coverages/coverage/name/text()').each do |n| 
        yield get_coverage(n.to_s.strip)
      end
    end
    
    # @param [String] name
    # @return [RGeoServer::Coverage]
    def get_coverage name
      Coverage.new catalog, :workspace => workspace, :coverage_store => self, :name => name
    end

    # <coverageStore>
    # <name>antietam_1867</name>
    # <description>
    # Map shows the U.S. Civil War battle of Antietam. It indicates fortifications, roads, railroads, houses, names of residents, fences, drainage, vegetation, and relief by hachures.
    # </description>
    # <type>GeoTIFF</type>
    # <enabled>true</enabled>
    # <workspace>
    # <name>druid</name>
    # <atom:link xmlns:atom="http://www.w3.org/2005/Atom" rel="alternate" href="http://localhost:8080/geoserver/rest/workspaces/druid.xml" type="application/xml"/>
    # </workspace>
    # <__default>false</__default>
    # <url>
    # file:///var/geoserver/current/staging/rumsey/g3881015alpha.tif
    # </url>
    # <coverages>
    # <atom:link xmlns:atom="http://www.w3.org/2005/Atom" rel="alternate" href="http://localhost:8080/geoserver/rest/workspaces/druid/coveragestores/antietam_1867/coverages.xml" type="application/xml"/>
    # </coverages>
    # </coverageStore>
    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml
      h = {
        'name' => doc.at_xpath('//name').text.strip, 
        'description' => doc.at_xpath('//description').text,
        'type' => doc.at_xpath('//type').text,
        'enabled' => doc.at_xpath('//enabled').text,
        'url' => doc.at_xpath('//url').text,
        'workspace' => workspace.name # Assume correct workspace
      }
      doc.xpath('//coverages/atom:link[@rel="alternate"]/@href', 
                "xmlns:atom"=>"http://www.w3.org/2005/Atom" ).each{ |l| 
        h['coverages'] = begin
          response = catalog.do_url l.text
          Nokogiri::XML(response).xpath('//name/text()').collect{ |a| a.text.strip }
        rescue RestClient::ResourceNotFound
          []
        end.freeze
      }
      h
    end

  end
end 
