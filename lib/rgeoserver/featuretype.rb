
module RGeoServer
  # A feature type is a vector based spatial resource or data set that originates from a data store.
  # In some cases, like Shapefile, a feature type has a one-to-one relationship with its data store.
  # In other cases, like PostGIS, the relationship of feature type to data store is many-to-one, with
  # each feature type corresponding to a table in the database.
  class FeatureType < ResourceInfo    
    OBJ_ATTRIBUTES = {
      :catalog => "catalog", 
      :name => "name", 
      :workspace => "workspace", 
      :data_store => "data_store", 
      :enabled => "enabled", 
      :metadata => "metadata", 
      :metadata_links => "metadataLinks", 
      :title => "title", 
      :abstract => "abstract",
      :keywords => 'keywords',
      :native_bounds => 'native_bounds', 
      :latlon_bounds => "latlon_bounds", 
      :projection_policy => 'projection_policy'
    }
    OBJ_DEFAULT_ATTRIBUTES = {
      :catalog => nil,
      :workspace => nil,
      :data_store => nil,
      :name => nil,
      :enabled => "false",
      :metadata => {},
      :metadata_links => {},
      :title => nil,
      :abstract => nil,
      :keywords => [],
      :native_bounds => {'minx'=>nil, 'miny' =>nil, 'maxx'=>nil, 'maxy'=>nil, 'crs' =>nil},
      :latlon_bounds => {'minx'=>nil, 'miny' =>nil, 'maxx'=>nil, 'maxy'=>nil, 'crs' =>nil},
      :projection_policy => :force
    }

    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    @@route = "workspaces/%s/datastores/%s/featuretypes"
    @@root = "featureTypes"
    @@resource_name = "featureType"

    # see http://inspire.ec.europa.eu/schemas/common/1.0/common.xsd
    @@metadata_types = {
      'ISO19139' => 'application/vnd.iso.19139+xml',
      'TC211' => 'application/vnd.iso.19139+xml'
    }

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
      raise GeoServerArgumentError, "workspace not defined" unless @workspace
      raise GeoServerArgumentError, "data_store not defined" unless @data_store
      @@route % [@workspace.name , @data_store.name]
    end
    
    def to_mimetype(type, default = 'text/xml')
      return @@metadata_types[type.upcase] if @@metadata_types.include?(type.upcase) 
      default
    end

    # Example: 
    # ft.keywords = [{:keyword => "United States", 
    #                 :language => "en", 
    #                 :vocabulary=>"ISOTC211/19115:place"}]
    # yields:
    #   United States\@language=en\;\@vocabulary=ISOTC211/19115:place\;
    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.featureType {
          xml.name @name if new?
          xml.enabled @enabled if new? or enabled_changed?
          xml.title title if new? or title_changed?
          xml.abstract abstract if new? or abstract_changed?
          xml.keywords {
            @keywords.each do |k|
              if k.is_a? Hash
                k = k.inject({}){|h,(k,v)| h[k.to_sym] = v; h}
                k = "#{k[:keyword]}" +
                    (("\\@language=#{k[:language]}\\;" if k[:language])||"") +
                    (("\\@vocabulary=#{k[:vocabulary]}\\;" if k[:vocabulary])||"")
              end
              xml.keyword k
            end
          } if @keywords and new? or keywords_changed?
          
          xml.metadata {
            @metadata.each do |k,v|
              xml.send(k.to_s, v.to_s)
            end
          } if @metadata and new? or metadata_changed?
          
          xml.metadataLinks {
            @metadata_links.each do |m|
              xml.metadataLink {
                xml.type_ to_mimetype(m['metadataType'])
                xml.metadataType m['metadataType']
                xml.content m['content']
              }
            end
          } if @metadata_links and new? or metadata_links_changed?
          
          xml.store(:class => 'dataStore') {
            xml.name @data_store.name
          } if new? or data_store_changed?

          xml.nativeBoundingBox {
            xml.minx native_bounds['minx'] if native_bounds['minx']
            xml.miny native_bounds['miny'] if native_bounds['miny']
            xml.maxx native_bounds['maxx'] if native_bounds['maxx']
            xml.maxy native_bounds['maxy'] if native_bounds['maxy']
            xml.crs native_bounds['crs'] if native_bounds['crs']
          } if valid_native_bounds?

          xml.latLonBoundingBox {
            xml.minx latlon_bounds['minx'] if latlon_bounds['minx']
            xml.miny latlon_bounds['miny'] if latlon_bounds['miny']
            xml.maxx latlon_bounds['maxx'] if latlon_bounds['maxx']
            xml.maxy latlon_bounds['maxy'] if latlon_bounds['maxy']
            xml.crs latlon_bounds['crs'] if latlon_bounds['crs']
          } if valid_latlon_bounds?

          xml.projectionPolicy get_projection_policy_message(projection_policy) if projection_policy

          if new?
            xml.attributes {
              xml.attribute {
                xml.name 'the_geom'
                xml.minOccurs 0
                xml.maxOccurs 1
                xml.nillable true
                xml.binding 'com.vividsolutions.jts.geom.Point'
              }
            }
          end
        }
      end
      @message = builder.doc.to_xml
    end


    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
    def initialize catalog, options
      raise GeoServerArgumentError, "FeatureType.new requires :data_store option" unless options.include?(:data_store)
      raise GeoServerArgumentError, "FeatureType.new requires :name option" unless options.include?(:name)
      
      _run_initialize_callbacks do
        @catalog = catalog
        workspace = options[:workspace] || 'default'
        if workspace.instance_of? String
          @workspace = @catalog.get_workspace(workspace)
        elsif workspace.instance_of? Workspace
          @workspace = workspace
        else
          raise GeoServerArgumentError, "Not a valid workspace: #{workspace}"
        end
        
        data_store = options[:data_store]
        if data_store.instance_of? String
          @data_store = @catalog.get_data_store(@workspace.name, data_store)
        elsif data_store.instance_of? DataStore
          @data_store = data_store
        else
          raise GeoServerArgumentError, "Not a valid datastore: #{data_store}"
        end

        @name = options[:name].strip
        @route = route
      end
    end

    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml
      h = {
        "name" => doc.at_xpath('//name').text.strip,
        "title" => doc.at_xpath('//title/text()').to_s,
        "abstract" => doc.at_xpath('//abstract/text()').to_s,
        "keywords" => doc.at_xpath('//keywordList').collect { |kl|
          {
            'keyword' => kl.at_xpath('//keyword/text()').to_s
          }
        },
        "workspace" => @workspace.name,
        "data_store" => @data_store.name,
        "nativeName" => doc.at_xpath('//nativeName/text()').to_s,
        "srs" => doc.at_xpath('//srs/text()').to_s,
        "native_bounds" => {
          'minx' => doc.at_xpath('//nativeBoundingBox/minx/text()').to_s.to_f,
          'miny' => doc.at_xpath('//nativeBoundingBox/miny/text()').to_s.to_f,
          'maxx' => doc.at_xpath('//nativeBoundingBox/maxx/text()').to_s.to_f,
          'maxy' => doc.at_xpath('//nativeBoundingBox/maxy/text()').to_s.to_f,
          'crs' => doc.at_xpath('//nativeBoundingBox/crs/text()').to_s
        },
        "latlon_bounds" => {
          'minx' => doc.at_xpath('//latLonBoundingBox/minx/text()').to_s.to_f,
          'miny' => doc.at_xpath('//latLonBoundingBox/miny/text()').to_s.to_f,
          'maxx' => doc.at_xpath('//latLonBoundingBox/maxx/text()').to_s.to_f,
          'maxy' => doc.at_xpath('//latLonBoundingBox/maxy/text()').to_s.to_f,
          'crs' => doc.at_xpath('//latLonBoundingBox/crs/text()').to_s
        },
        "projection_policy" => get_projection_policy_sym(doc.at_xpath('//projectionPolicy').text.strip),
        "metadataLinks" => doc.xpath('//metadataLinks/metadataLink').collect{ |m|
          {
            'type' => m.at_xpath('//type/text()').to_s,
            'metadataType' => m.at_xpath('//metadataType/text()').to_s,
            'content' => m.at_xpath('//content/text()').to_s
          }
        },
        "attributes" => doc.xpath('//attributes/attribute').collect{ |a|
          {
            'name' => a.at_xpath('//name/text()').to_s,
            'minOccurs' => a.at_xpath('//minOccurs/text()').to_s,
            'maxOccurs' => a.at_xpath('//maxOccurs/text()').to_s,
            'nillable' => a.at_xpath('//nillable/text()').to_s,
            'binding' => a.at_xpath('//binding/text()').to_s
          }
        }
      }.freeze
      h
    end

    def valid_native_bounds?
      native_bounds &&
        ![native_bounds['minx'], native_bounds['miny'], native_bounds['maxx'], native_bounds['maxy'], native_bounds['crs']].compact.empty?
    end

    def valid_latlon_bounds?
      latlon_bounds &&
        ![latlon_bounds['minx'], latlon_bounds['miny'], latlon_bounds['maxx'], latlon_bounds['maxy'], latlon_bounds['crs']].compact.empty?
    end

    private
    def get_projection_policy_sym value
      case value.upcase
      when 'FORCE_DECLARED' then :force
      when 'REPROJECT_TO_DECLARED' then :reproject
      when 'NONE' then :keep
      else
        raise GeoServerArgumentError, "There is not correspondent to '%s'" % value
      end
    end

    def get_projection_policy_message value
      case value
      when :force then 'FORCE_DECLARED'
      when :reproject then 'REPROJECT_TO_DECLARED'
      when :keep then 'NONE'
      else
        raise GeoServerArgumentError, "There is not correspondent to '%s'" % value
      end
    end
  end
end
