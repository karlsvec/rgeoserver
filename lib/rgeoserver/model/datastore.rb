
module RGeoServer
  # A data store is a source of spatial data that is vector based. It can be a file in the case of a Shapefile, a database in the case of PostGIS, or a server in the case of a remote Web Feature Service.
  class DataStore < ResourceInfo

    OBJ_ATTRIBUTES = {
      :workspace => 'workspace', 
      :connection_parameters => "connection_parameters",
      :name => 'name', 
      :data_type => 'type', 
      :enabled => 'enabled', 
      :description => 'description'
    }  
    OBJ_DEFAULT_ATTRIBUTES = {
      :workspace => nil, 
      :connection_parameters => {}, 
      :name => nil, 
      :data_type => :shapefile,
      :enabled => true, 
      :description => nil
    }  
    
    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    attr_accessor :message

    # @param [RGeoServer::Catalog] catalog
    # @param [RGeoServer::Workspace|String] options `:workspace`, `:name`
    def initialize catalog, options
      super(catalog)
      _run_initialize_callbacks do
        raise GeoServerArgumentError, "#{self.class}.new requires :workspace option" unless options.include?(:workspace)
        ws = options[:workspace]
        if ws.instance_of? String
          workspace = catalog.get_workspace(ws)
        elsif ws.instance_of? Workspace
          workspace = ws
        else
          raise GeoServerArgumentError, "Not a valid workspace: #{ws}"
        end
        
        raise GeoServerArgumentError, "#{self.class}.new requires :name option" unless options.include?(:name)
        name = options[:name].to_s.strip
      end
    end

    def message
      Nokogiri::XML::Builder.new do |xml|
        xml.dataStore {
          xml.name name
          xml.enabled enabled
          xml.description description
          xml.type_ data_type if data_type_changed? or new?
          xml.connectionParameters {  # this could be empty
            connection_parameters.each_pair { |k,v|
              xml.entry(:key => k) {
                xml.text v
              }
            } unless connection_parameters.nil? or connection_parameters.empty?
          }
        }
      end.doc.to_xml
    end

    # @yield [RGeoServer::FeatureType]
    def featuretypes
      doc = Nokogiri::XML(catalog.search :workspaces => workspace.name, :datastores => name, :featuretypes => nil)
      doc.xpath('/featureTypes/featureType/name').each do |n| 
        yield get_featuretype(n.text.strip)
      end
    end

    # @param [String] name
    # @return [RGeoServer::FeatureType]
    def get_featuretype name
      FeatureType.new catalog, :workspace => workspace, :datastore => self, :name => name
    end

    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml
      h = {
        "name" => doc.at_xpath('//name').text.strip,
        "description" => doc.at_xpath('//description').text,
        "enabled" => doc.at_xpath('//enabled').text,
        'type' => doc.at_xpath('//type').text,
        "connection_parameters" => doc.xpath('//connectionParameters/entry').inject({}){ |x, e| x.merge(e['key']=> e.text.to_s) }
      }
      # XXX: assume that we know the workspace for <workspace>...</workspace>
      doc.xpath('//featureTypes/atom:link[@rel="alternate"]/@href', 
                "xmlns:atom"=>"http://www.w3.org/2005/Atom" ).each do |l|
        h["featureTypes"] = begin
                              response = catalog.do_url l.text
                              # lazy loading: only loads featuretype names
                              Nokogiri::XML(response).xpath('//name/text()').collect{ |a| a.text.strip }
                            rescue RestClient::ResourceNotFound
                              []
                            end.freeze
      end
      h
    end
  end
end
