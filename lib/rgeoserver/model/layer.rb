
module RGeoServer
  # A layer is a published resource (feature type or coverage).
  class Layer < ResourceInfo
    # attr_accessors
    # @see http://geoserver.org/display/GEOS/Catalog+Design
    OBJ_ATTRIBUTES = { 
      :enabled => 'enabled', 
      :queryable => 'queryable', 
      :path => 'path', 
      :catalog => 'catalog', 
      :name => 'name', 
      :default_style => 'default_style', 
      :alternate_styles => 'alternate_styles', 
      :metadata => 'metadata', 
      :attribution => 'attribution', 
      :layer_type => 'type' 
    }
    OBJ_DEFAULT_ATTRIBUTES = {
      :enabled => 'true',
      :queryable => 'true',
      :path => '/',
      :catalog => nil,
      :name => nil,
      :default_style => nil,
      :alternate_styles => [],
      :metadata => {
        'GWC.autoCacheStyles' => 'true',
        'GWC.gutter' => '0',
        'GWC.enabled' => 'true',
        'GWC.cacheFormats' => 'image/jpeg,image/png',
        'GWC.gridSets' => 'EPSG:4326,EPSG:900913'
      },
      :attribution => {
        'logo_height' => '0',
        'logo_width' => '0',
        'title' => ''
      },
      :layer_type => nil
    }

    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    # @return [OrderedHash]
    def route
      { :layers => @name }
    end
    
    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
    # @option options [String] :name required
    # @option options [String] :default_style
    # @option options [Array<String>] :alternate_styles
    def initialize catalog, options
      super(catalog)
      run_callbacks :initialize do
        raise RGeoServer::ArgumentError, "#{self.class}.new requires :name option" unless options.include?(:name)
        if options[:name].instance_of? Layer
          @name = options[:name].name
        else
          @name = options[:name].to_s.strip
        end
      end
    end

    def resource= r
      if r.is_a?(RGeoServer::Coverage) || r.is_a?(RGeoServer::FeatureType)
        @resource = r
      else
        raise RGeoServer::ArgumentError, "Unknown resource type: #{r.class}"
      end
    end

    def resource
      @resource ||= begin
        unless profile['resource'].empty?
          data_type = profile['resource']['type']
          workspace = profile['resource']['workspace']
          name = profile['resource']['name']
          store = profile['resource']['store']

          case data_type
          when 'coverage'
            return RGeoServer::Coverage.new catalog, :workspace => workspace, :coverage_store => store, :name => name
          when 'featureType'
            begin
              ft = RGeoServer::FeatureType.new catalog, :workspace => workspace, :data_store => store, :name => name
            rescue Exception => e
            end
            
            return ft
          else
            raise RGeoServer::ArgumentError, "Unknown resource type: #{data_type}"
          end
        else
          nil
        end
      rescue Exception => e
        nil
      end
    end

    def styles
      raise NotImplemented
    end
    
    def get_style name
      raise NotImplemented
    end
    
    def workspace
      resource.workspace
    end

    # Return full name of resource with namespace prefix
    def prefixed_name
      return "#{workspace.name}:#{name}" if self.respond_to?(:workspace)
      raise RGeoServer::ArgumentError, "Workspace is not defined for this resource"
    end

    #= GeoWebCache Operations for this layer
    # See http://geowebcache.org/docs/current/rest/seed.html
    # See RGeoServer::Catalog.seed_terminate for stopping pending and/or running tasks for any layer
    #
    # Example:
    #  > lyr = RGeoServer::Layer.new catalog, :name => 'Arc_Sample'
    #  > options = {
    #    :srs => {:number => 4326 },
    #    :zoomStart => 1,
    #    :zoomStop => 12,
    #    :format => 'image/png',
    #    :threadCount => 1
    #  }
    #  > lyr.seed :issue, options
    #
    # @see http://geowebcache.org/docs/current/rest/
    # @param[String] operation
    # @option operation[Symbol] :issue seed
    # @option operation[Symbol] :truncate seed
    # @option operation[Symbol] :status of the seeding thread
    # @param[Hash] options for seed message. Read the documentation
    def seed operation, options
      op = operation.to_sym
      sub_path = "seed/#{prefixed_name}"
      case op
      when :issue
        catalog.do_url sub_path, _build_seed_request(:seed, options), :post, {}, catalog.gwc_client
      when :truncate
        catalog.do_url sub_path, _build_seed_request(:truncate, options), :post, {}, catalog.gwc_client
      when :status
        raise NotImplementedError, "#{op}"
      end
    end

    protected
    def message
      Nokogiri::XML::Builder.new do |xml|
        xml.layer {
          xml.name name
          xml.path path
          xml.type_ layer_type
          xml.enabled enabled
          xml.queryable queryable
          xml.defaultStyle {
            xml.name default_style
          }
          xml.styles {
            alternate_styles.each { |s|
              xml.style {
                xml.name s
              }
            }
          } unless alternate_styles.empty?
          xml.resource(:class => resource.class.resource_name){
            xml.name resource.name
          } unless resource.nil?
          xml.metadata {
            metadata.each_pair { |k,v|
              xml.entry(:key => k) {
                xml.text v
              }
            }
          }
          xml.attribution {
            xml.title attribution['title'] unless attribution['title'].empty?
            xml.logoWidth attribution['logo_width']
            xml.logoHeight attribution['logo_height']
          } if !attribution['logo_width'].nil? && !attribution['logo_height'].nil?
        }
      end.doc.to_xml
    end

    def profile_xml_to_hash xml
      doc = Nokogiri::XML(xml).at_xpath('/layer')
      name = doc.at_xpath('//name').text.strip
      link = doc.at_xpath('//resource//atom:link/@href', "xmlns:atom"=>"http://www.w3.org/2005/Atom").text.strip
      workspace, _, store = link.match(/workspaces\/(.*?)\/(.*?)\/(.*?)\/(.*?)\/#{name}.xml$/).to_a[1,3]

      h = {
        "name" => name,
        "path" => doc.at_xpath('//path').text,
        "default_style" => doc.at_xpath('//defaultStyle/name').text,
        "alternate_styles" => doc.xpath('//styles/style/name').collect{ |s| s.text},
        # Types can be: VECTOR, RASTER, REMOTE, WMS
        "type" => doc.at_xpath('//type').text,
        "enabled" => doc.at_xpath('//enabled').text,
        "queryable" => doc.at_xpath('//queryable').text,
        "attribution" => {
          "title" => doc.at_xpath('//attribution/title').text,
          "logo_width" => doc.at_xpath('//attribution/logoWidth').text,
          "logo_height" => doc.at_xpath('//attribution/logoHeight').text
        },
        "resource" => {
          "type" => doc.at_xpath('//resource/@class').to_s,
          "name" => doc.at_xpath('//resource/name').text,
          "store" => store,
          "workspace" => workspace
        },
        "metadata" => doc.xpath('//metadata/entry').inject({}){ |h2, e| h2.merge(e['key']=> e.text.to_s) }
      }.freeze
      h
    end


    private
    # @param[Hash] options for seed message, requiring
    #  options[:srs][:number]
    #  options[:bounds][:coords]
    #  options[:gridSetId]
    #  options[:zoomStart]
    #  options[:zoomStop]
    #  options[:gridSetId]
    #  options[:gridSetId]
    #
    def _build_seed_request operation, options
      Nokogiri::XML::Builder.new do |xml|
        xml.seedRequest {
          xml.name prefixed_name

          xml.srs {
            xml.number options[:srs][:number]
          } unless options[:srs].nil? #&& options[:srs].is_a?(Hash)

          xml.bounds {
            xml.coords {
              options[:bounds][:coords].each { |dbl|
                xml.double dbl
              }
            }
          } unless options[:bounds].nil?

          xml.type_ operation

          [:gridSetId, :zoomStart, :zoomStop, :threadCount].each { |p|
            eval "xml.#{p.to_s} options[p]" unless options[p].nil?
          }
          
          xml.format_ options[:tileFormat] unless options[:tileFormat].nil?

          xml.parameters {
            options[:parameters].each_pair { |k,v|
              xml.entry {
                xml.string k.upcase
                xml.string v
              }
            }
          } if options[:parameters].is_a?(Hash)
        }
      end.doc.to_xml
    end
  end

end
