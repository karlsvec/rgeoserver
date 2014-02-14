
module RGeoServer
  # A workspace is a grouping of data stores. More commonly known as a namespace, 
  # it is commonly used to group data that is related in some way.
  class Workspace < ResourceInfo

    OBJ_ATTRIBUTES = {
      :enabled => 'enabled', 
      :catalog => 'catalog', 
      :name => 'name' 
    }
    OBJ_DEFAULT_ATTRIBUTES = {
      :enabled => 'true', 
      :catalog => nil, 
      :name => nil 
    }

    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    @@route = "workspaces"
    @@resource_name = "workspace"

    def self.resource_name
      @@resource_name
    end

    def self.root_xpath
      "//#{@@route}/#{@@resource_name}"
    end

    def self.member_xpath
      "//#{resource_name}"
    end

    def route
      @@route  
    end

    # @return [String] XML document with workspace attributes
    def message
      Nokogiri::XML::Builder.new do |xml|
        xml.workspace { 
          xml.enabled @enabled if enabled_changed?
          xml.name @name 
        }
      end.doc.to_xml 
    end

    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
    def initialize catalog, options
      super(catalog)
      _run_initialize_callbacks do
        @name = options[:name].strip
      end        
      @route = route
    end
    
    #= Data Stores (Vector datasets)

    # @yield [RGeoServer::DataStore]
    def datastores
      doc = Nokogiri::XML(search :workspaces => @name, :datastores => nil)
      doc.xpath('/dataStores/dataStore/name/text()').each do |name| 
        yield get_datastore(name.to_s.strip)
      end
    end

    # @param [String] name
    # @return [RGeoServer::DataStore]
    def get_datastore name
      DataStore.new @catalog, :workspace => self, :name => name
    end

    #= Coverages (Raster datasets)

    # @param [String] workspace
    # @yield [RGeoServer::CoverageStore]
    def coveragestores 
      doc = Nokogiri::XML(search :workspaces => @name, :coveragestores => nil)
      doc.xpath('/coverageStores/coverageStore/name/text()').collect do |name| 
        yield get_coveragestore(name.to_s.strip)
      end
    end

    # @param [String] workspace
    # @param [String] name
    # @return [RGeoServer::CoverageStore]
    def get_coveragestore name
      CoverageStore.new @catalog, :workspace => self, :name => name
    end

    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml 
      h = {
        'name' => doc.at_xpath('//name').text.strip, 
        'enabled' => @enabled 
      }
      doc.xpath('//atom:link/@href', "xmlns:atom"=>"http://www.w3.org/2005/Atom").each{ |l| 
        target = l.text.match(/([a-zA-Z]+)\.xml$/)[1]
        if !target.nil? && target != l.parent.parent.name.to_s.downcase
          begin
            h[l.parent.parent.name.to_s] << target
          rescue
            h[l.parent.parent.name.to_s] = []
          end
        else
          h[l.parent.parent.name.to_s] = begin
            response = @catalog.do_url l.text
            Nokogiri::XML(response).xpath('//name').collect{ |a| a.text.strip }
          rescue RestClient::ResourceNotFound
            []
          end.freeze
        end
       }
      h  
    end
  end
end 
