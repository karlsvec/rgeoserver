
module RGeoServer

    class DataStores < ResourceInfo
  
      OBJ_ATTRIBUTES = {:enabled => "enabled", :catalog => "catalog", :workspace => "workspace", :name => "name"} 
      OBJ_DEFAULT_ATTRIBUTES = {:enabled => 'true', :catalog => nil, :workspace => nil, :name => nil, }
      define_attribute_methods OBJ_ATTRIBUTES.keys
      update_attribute_accessors OBJ_ATTRIBUTES
 
      @@r = Confstruct::Configuration.new(
          :route => "workspaces/%s/datastores",
          :root => "dataStores",
          :resource_name => "dataStore"
        )

      def self.root
        @@r.root
      end

      def self.create_method
        :put 
      end

      def self.update_method
        :put 
      end

      def self.resource_name
        @@r.resource_name
      end
 
      def self.root_xpath
        "//#{root}/#{resource_name}"
      end

      def self.member_xpath
        "//#{resource_name}"
      end

      def route
        @@r.route % @workspace.name 
      end

      def message
        builder = Nokogiri::XML::Builder.new do |xml|
          xml.dataStore {
            xml.enabled @enabled
            xml.name @name
          }
        end
        return builder.doc.to_xml 
      end

      # @param [RGeoServer::Catalog] catalog
      # @param [RGeoServer::Workspace|String] workspace
      # @param [String] name
      def initialize catalog, options 
        super({})
        _run_initialize_callbacks do
          @catalog = catalog
          workspace = options[:workspace] || 'default'
          if workspace.instance_of? String
            @workspace = @catalog.get_workspace(workspace)
          elsif workspace.instance_of? Workspace
            @workspace = workspace
          else
            raise "Not a valid workspace"
          end
          @name = options[:name].strip
          @connection_parameters = options[:connection_parameters] || {}
          @route = route
        end        
      end

      def data_stores
        profile['dataStores'].collect{ |name|
          DataStore.new @catalog, :workspace => @workspace, :data_store => self, :name => name
        }
      end

    end
end 
