
module RGeoServer
  # A feature type is a vector based spatial resource or data set that originates from a data store.
  # In some cases, like Shapefile, a feature type has a one-to-one relationship with its data store.
  # In other cases, like PostGIS, the relationship of feature type to data store is many-to-one, with
  # each feature type corresponding to a table in the database.
  class FeatureType < ResourceInfo    
    OBJ_ATTRIBUTES = {
      :catalog => "catalog", 
      :name => "name", 
      :native_name => "nativeName", 
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
      :native_name => nil,
      :enabled => "false",
      :metadata => {},
      :metadata_links => {},
      :title => nil,
      :abstract => nil,
      :keywords => [],
      :native_bounds => {'minx'=>nil, 'miny' =>nil, 'maxx'=>nil, 'maxy'=>nil, 'crs' =>nil},
      :latlon_bounds => {'minx'=>nil, 'miny' =>nil, 'maxx'=>nil, 'maxy'=>nil, 'crs' =>nil},
      :projection_policy => :keep
    }

    define_attribute_methods OBJ_ATTRIBUTES.keys
    update_attribute_accessors OBJ_ATTRIBUTES

    @@route = "workspaces/%s/datastores/%s/featuretypes"
    @@root = "featureTypes"
    @@resource_name = "featureType"

    # see http://inspire.ec.europa.eu/schemas/common/1.0/common.xsd
    METADATA_TYPES = {
      'ISO19139' => 'text/xml',
      'TC211' => 'text/xml'
    }
    
    # see https://github.com/geoserver/geoserver/blob/master/src/main/src/main/java/org/geoserver/catalog/ProjectionPolicy.java
    PROJECTION_POLICIES = {
      :force => 'FORCE_DECLARED',
      :reproject => 'REPROJECT_TO_DECLARED',
      :keep => 'NONE'
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
      k = type.to_s.strip.upcase
      return METADATA_TYPES[k] if METADATA_TYPES.include? k
      default
    end

    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.featureType {
          xml.nativeName @native_name.nil?? @name : @native_name if new? # on new only
          xml.name @name
          xml.enabled @enabled
          xml.title @title
          xml.abstract @abstract
          xml.keywords {
            @keywords.compact.uniq.each do |k|
              xml.string RGeoServer::Metadata::to_keyword(k)
            end
          } unless @keywords.empty?

          xml.metadataLinks {
            @metadata_links.each do |m|
              raise ArgumentError, "Malformed metadata_links" unless m.is_a? Hash
              xml.metadataLink {
                xml.type_ to_mimetype(m['metadataType'])
                xml.metadataType m['metadataType']
                xml.content m['content']
              }
            end
          } unless @metadata_links.empty?
          
          xml.store(:class => 'dataStore') {
            xml.name @data_store.name
          } if new? or data_store_changed?

          xml.nativeBoundingBox {
            xml.minx native_bounds['minx'] if native_bounds['minx']
            xml.miny native_bounds['miny'] if native_bounds['miny']
            xml.maxx native_bounds['maxx'] if native_bounds['maxx']
            xml.maxy native_bounds['maxy'] if native_bounds['maxy']
            xml.crs native_bounds['crs'] if native_bounds['crs']
          } if valid_native_bounds? and (new? or native_bounds_changed?)

          xml.latLonBoundingBox {
            xml.minx latlon_bounds['minx'] if latlon_bounds['minx']
            xml.miny latlon_bounds['miny'] if latlon_bounds['miny']
            xml.maxx latlon_bounds['maxx'] if latlon_bounds['maxx']
            xml.maxy latlon_bounds['maxy'] if latlon_bounds['maxy']
            xml.crs latlon_bounds['crs'] if latlon_bounds['crs']
          } if valid_latlon_bounds? and (new? or latlon_bounds_changed?)

          xml.projectionPolicy get_projection_policy_message(projection_policy) if projection_policy and new? or projection_policy_changed?

          if new? # XXX: hard coded attributes
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
      ap({:message => @message}) if $DEBUG
      @message
    end


    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
    def initialize catalog, options
      raise GeoServerArgumentError, "FeatureType.new requires :data_store option" unless options.include?(:data_store)
      raise GeoServerArgumentError, "FeatureType.new requires :name option" unless options.include?(:name)
      super(catalog)
      _run_initialize_callbacks do
        workspace = options[:workspace] || 'default'
        if workspace.instance_of? String
          @workspace = @catalog.get_workspace(workspace)
        elsif workspace.instance_of? Workspace
          @workspace = workspace
        else
          raise GeoServerArgumentError, "Not a valid workspace: #{workspace}"
        end
        
        data_store = options[:datastore]
        if data_store.instance_of? String
          @data_store = @workspace.get_datastore(data_store)
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
      ft = doc.at_xpath('//' + FeatureType::resource_name)
      ap({:doc => doc, :ft => ft}) if $DEBUG
      h = {
        "name" => ft.at_xpath('name').text,
        "native_name" => ft.at_xpath('nativeName').text,
        "title" => ft.at_xpath('title').text,
        "abstract" => ft.at_xpath('abstract/text()'), # optional
        "keywords" => ft.xpath('keywords/string').collect { |k| k.at_xpath('.').text},
        "workspace" => @workspace.name,
        "data_store" => @data_store.name,
        "srs" => ft.at_xpath('srs').text,
        "native_bounds" => {
          'minx' => ft.at_xpath('nativeBoundingBox/minx').text.to_f,
          'miny' => ft.at_xpath('nativeBoundingBox/miny').text.to_f,
          'maxx' => ft.at_xpath('nativeBoundingBox/maxx').text.to_f,
          'maxy' => ft.at_xpath('nativeBoundingBox/maxy').text.to_f,
          'crs' => ft.at_xpath('srs').text
        },
        "latlon_bounds" => {
          'minx' => ft.at_xpath('latLonBoundingBox/minx').text.to_f,
          'miny' => ft.at_xpath('latLonBoundingBox/miny').text.to_f,
          'maxx' => ft.at_xpath('latLonBoundingBox/maxx').text.to_f,
          'maxy' => ft.at_xpath('latLonBoundingBox/maxy').text.to_f,
          'crs' => ft.at_xpath('latLonBoundingBox/crs').text
        },
        "projection_policy" => get_projection_policy_sym(ft.at_xpath('projectionPolicy').text),
        "metadata_links" => ft.xpath('metadataLinks/metadataLink').collect{ |m|
          {
            'type' => m.at_xpath('type').text,
            'metadataType' => m.at_xpath('metadataType').text,
            'content' => m.at_xpath('content').text
          }
        },
        "attributes" => ft.xpath('attributes/attribute').collect{ |a|
          {
            'name' => a.at_xpath('name').text,
            'minOccurs' => a.at_xpath('minOccurs').text,
            'maxOccurs' => a.at_xpath('maxOccurs').text,
            'nillable' => a.at_xpath('nillable').text,
            'binding' => a.at_xpath('binding').text
          }
        }
      }.freeze
      ap({:h => h}) if $DEBUG
      h
    end

    def valid_native_bounds?
      bbox = RGeoServer::BoundingBox.new(native_bounds)
      ap bbox if $DEBUG
      not bbox.nil? and bbox.valid? and not native_bounds['crs'].empty?
    end

    def valid_latlon_bounds?
      bbox = RGeoServer::BoundingBox.new(latlon_bounds)
      ap bbox if $DEBUG
      not bbox.nil? and bbox.valid? and not latlon_bounds['crs'].empty?
    end
    
    def update_params name_route = name
      super(name_route)
      # recalculate='nativebbox,latlonbbox'
    end

    private
    
    def get_projection_policy_sym value
      v = value.strip.upcase
      if PROJECTION_POLICIES.has_value? v
        PROJECTION_POLICIES.invert[v]
      else
        raise GeoServerArgumentError, "Invalid PROJECTION_POLICY: #{v}"
      end
    end

    def get_projection_policy_message value
      k = value
      k = value.strip.to_sym if not value.is_a? Symbol
      if PROJECTION_POLICIES.has_key? k
        PROJECTION_POLICIES[k]
      else
        raise GeoServerArgumentError, "Invalid PROJECTION_POLICY: #{k}"
      end
    end
  end
end
