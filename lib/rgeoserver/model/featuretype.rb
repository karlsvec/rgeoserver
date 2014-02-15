
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

    def to_mimetype(type, default = 'text/xml')
      k = type.to_s.strip.upcase
      return METADATA_TYPES[k] if METADATA_TYPES.include? k
      default
    end

    def message
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.featureType {
          xml.nativeName native_name.nil?? name : native_name if new? # on new only
          xml.name name
          xml.enabled enabled
          xml.title title
          xml.abstract abstract
          xml.keywords {
            keywords.compact.uniq.each do |k|
              xml.string RGeoServer::Metadata::to_keyword(k)
            end
          } unless keywords.empty?

          xml.metadataLinks {
            metadata_links.each do |m|
              raise ArgumentError, "Malformed metadata_links" unless m.is_a? Hash
              xml.metadataLink {
                xml.type_ to_mimetype(m['metadataType'])
                xml.metadataType m['metadataType']
                xml.content m['content']
              }
            end
          } unless metadata_links.empty?
          
          xml.store(:class => 'dataStore') {
            xml.name data_store.name
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
      @message
    end


    # @param [RGeoServer::Catalog] catalog
    # @param [Hash] options
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
        
        raise GeoServerArgumentError, "#{self.class}.new requires :datastore option" unless options.include?(:datastore)
        ds = options[:datastore]
        if ds.instance_of? String
          data_store = workspace.get_datastore(ds)
        elsif ds.instance_of? DataStore
          data_store = ds
        else
          raise GeoServerArgumentError, "Not a valid datastore: #{ds}"
        end

        raise GeoServerArgumentError, "#{self.class}.new requires :name option" unless options.include?(:name)
        name = options[:name].to_s.strip
      end
    end

    def profile_xml_to_hash profile_xml
      doc = profile_xml_to_ng profile_xml
      ft = doc.at_xpath('//featureType')
      {
        "name" => ft.at_xpath('name').text.strip,
        "native_name" => ft.at_xpath('nativeName').text.strip,
        "title" => ft.at_xpath('title').text,
        "abstract" => ft.at_xpath('abstract/text()'), # optional
        "keywords" => ft.xpath('keywords/string').collect { |k| k.at_xpath('.').text},
        "workspace" => workspace.name,
        "data_store" => datastore.name,
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
    end

    def valid_native_bounds?
      bbox = RGeoServer::BoundingBox.new(native_bounds)
      not bbox.nil? and bbox.valid? and not native_bounds['crs'].empty?
    end

    def valid_latlon_bounds?
      bbox = RGeoServer::BoundingBox.new(latlon_bounds)
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
      k = k.strip.to_sym if not k.is_a? Symbol
      if PROJECTION_POLICIES.has_key? k
        PROJECTION_POLICIES[k]
      else
        raise GeoServerArgumentError, "Invalid PROJECTION_POLICY: #{k}"
      end
    end
  end
end
