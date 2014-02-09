
module RGeoServer
  # A data store is a source of spatial data that is vector based. It can be a file in the case of a Shapefile, a database in the case of PostGIS, or a server in the case of a remote Web Feature Service.
  class DataStore < ResourceInfo

    class DataStoreAlreadyExists < StandardError
      def initialize(name)
        @name = name
      end

      def message
        "The DataStore '#{@name}' already exists and can not be replaced."
      end
    end

    class DataTypeNotExpected < StandardError
      def initialize(data_type)
        @data_type = data_type
      end

      def message
        "The DataStore does not not accept the data type '#{@data_type}'."
      end
    end

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

    @@route = "workspaces/%s/datastores"
    @@root = "dataStores"
    @@resource_name = "dataStore"

    def self.root
      @@root
    end

    def self.resource_name
      @@resource_name
    end

    def self.root_xpath
      "//#{root}/#{resource_name}"
    end

    def self.member_xpath
      "//#{resource_name}"
    end

    def route
      @@route % @workspace.name
    end

    def update_route
      "#{route}/#{@name}"
    end

    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.dataStore {
          xml.name @name
          xml.enabled @enabled
          xml.description @description
          xml.type_ @data_type if (data_type_changed? || new?)
          xml.connectionParameters {  # this could be empty
            @connection_parameters.each_pair { |k,v|
              xml.entry(:key => k) {
                xml.text v
              }
            } unless @connection_parameters.nil? || @connection_parameters.empty?
          }
        }
      end
      # ap builder.doc
      builder.doc.to_xml
    end

    # @param [RGeoServer::Catalog] catalog
    # @param [RGeoServer::Workspace|String] options `:workspace`
    # options `:name`
    def initialize catalog, options
      super({})
      _run_initialize_callbacks do
        @catalog = catalog
        workspace = options[:workspace] || 'default'
        if workspace.instance_of? String
          @workspace = catalog.get_workspace(workspace)
        elsif workspace.instance_of? Workspace
          @workspace = workspace
        else
          raise ArgumentError, "Not a valid workspace: #{workspace}"
        end

        @name = options[:name].strip
        @route = route
      end
    end

    def featuretypes &block
      self.class.list FeatureType, catalog, profile['featureTypes'], {:workspace => @workspace, :data_store => self}, true, &block
    end

    def upload_file local_file, publish = {}
      upload local_file, :file, data_type, publish
    end
    def upload_external remote_file, publish = {}
      puts "Uploading external file #{remote_file} #{publish}"
      upload remote_file, :external, data_type, publish
    end
    def upload_url url, publish = {}
      upload url, :url, data_type, publish
    end
    
    # @param [String] path - location of upload data
    # @param [Symbol] upload_method -- flag for :file, :url, or :external
    # @param [Symbol] data_type -- currently only :shapefile
    # @param [Boolean] publish -- only valid for :file  
    def upload path, upload_method = :file, data_type = :shapefile, publish = false
      ap({ :path => path, :upload_method => upload_method, :data_type => data_type, :publish => publish, :self => self}) if $DEBUG

      raise DataStoreAlreadyExists, @name unless new?
      raise DataTypeNotExpected, data_type unless [:shapefile].include? data_type

      ext = 'shp'
      case upload_method
      when :file then # local file that we post
        local_file = File.expand_path(path)
        unless local_file =~ %r{\.zip$} and File.exist? local_file
          raise ArgumentError, "Shapefile upload must be ZIP file: #{local_file}" 
        end
        puts "Uploading #{File.size(local_file)} bytes from file #{local_file}..."
        
        catalog.client["#{route}/#{name}/file.#{ext}"].put File.read(local_file), :content_type => 'application/zip'
        refresh
      when :external then # remote file that we reference
        catalog.client["#{route}/#{name}/external.#{ext}"].put path, :content_type => 'text/plain'
      when :url then
        catalog.client["#{route}/#{name}/url.#{ext}"].put path, :content_type => 'text/plain'
      else
        raise NotImplementedError, "Unsupported upload method #{upload_method}"
      end
      self
    end

    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml
      h = {
        "name" => doc.at_xpath('//name').text.strip,
        "description" => doc.at_xpath('//description/text()').to_s,
        "enabled" => doc.at_xpath('//enabled/text()').to_s,
        'type' => doc.at_xpath('//type/text()').to_s,
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
