
module RGeoServer
  # base class for all GeoServer resources
  class ResourceInfo

    include ActiveModel::Dirty
    extend ActiveModel::Callbacks

    define_model_callbacks :save, :destroy
    define_model_callbacks :initialize, :only => :after

    # @return [RGeoServer::Catalog]
    attr_accessor :catalog
    
    # mapping object parameters to profile elements
    # attr_accessors
    # @see http://geoserver.org/display/GEOS/Catalog+Design
    OBJ_ATTRIBUTES = {
      :enabled => 'enabled'
    }
    OBJ_DEFAULT_ATTRIBUTES = {
      :enabled => 'true'
    }

    protected
    define_attribute_methods OBJ_ATTRIBUTES.keys

    def self.update_attribute_accessors attributes
      attributes.each do |attribute, profile_name|
        class_eval %Q{
        def #{attribute.to_s}
          @#{attribute} || profile['#{profile_name.to_s}'] || OBJ_DEFAULT_ATTRIBUTES[:#{attribute}]
        end

        def #{attribute.to_s}= val
          #{attribute.to_s}_will_change! unless val == #{attribute.to_s}
          @#{attribute.to_s} = val
        end
      }
      end
    end

    public
    # @param [RGeoServer::Catalog] catalog
    def initialize catalog
      @new = true
      @catalog = catalog
    end

    # @return [String]
    def to_s
      "#{self.class}: #{@name} (#{new?}) on #{@catalog}"
    end

    # Modify or save the resource
    # @param [Hash] options / query parameters
    # @return [RGeoServer::ResourceInfo]
    def save options = {}
      @previously_changed = changes
      @changed_attributes.clear
      run_callbacks :save do
        if new? # need to create
          @catalog.add(route, message, options)
        else # exists
          @catalog.modify(route, message, options)
        end
        refresh
      end
    end

    # Purge resource from Geoserver Catalog
    # @param [Hash] options
    # @return [RGeoServer::ResourceInfo]
    def delete options = {}
      run_callbacks :destroy do
        @catalog.purge(route, options) unless new?
        refresh
      end
    end

    # Check if this resource already exists
    # @return [Boolean]
    def new?
      profile
      @new
    end

    # clear changes
    def clear
      @profile = nil
      @changed_attributes = {}
    end
    
    # @return [RGeoServer::ResourceInfo]
    def refresh
      clear
      profile
      self
    end

    protected
    # Retrieve the resource profile as a hash and cache it
    # @return [Hash]
    def profile
      unless @profile
        begin
          self.profile = @catalog.search route
          @new = false
        rescue RestClient::ResourceNotFound # The resource is new
          @profile = {}
          @new = true
        end
        @profile.freeze unless @profile.frozen?
      end
      @profile
    end

    # @param [String] data
    # @return [Hash]
    def profile= data, type = :json
      case type
      when :xml
        @profile = profile_xml_to_hash(data)
      when :json
        @profile = profile_json_to_hash(data)
      else
        raise NotImplementedError, "profile= does not support #{type}"
      end
      @profile.freeze
    end

    # @abstract
    # @return [Nokogiri::XML]
    def profile_xml_to_ng xml
      raise NotImplementedError, 'profile_xml_to_ng is abstract method'
    end
    # @abstract
    # @return [Hash]
    def profile_xml_to_hash xml
      raise NotImplementedError, 'profile_xml_to_hash is abstract method'
    end
    # @abstract
    # @return [Hash]
    def profile_json_to_hash json
      raise NotImplementedError, 'profile_json_to_hash is abstract method'
    end
    # @abstract
    # @return [String]
    def message
      raise NotImplementedError, 'message is abstract method'
    end
    # @abstract
    # @return [OrderedHash]
    def route
      raise NotImplementedError, 'route is abstract method'
    end
  end
end
