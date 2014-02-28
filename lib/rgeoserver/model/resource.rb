
module RGeoServer
  # base class for all GeoServer resources
  class ResourceInfo < ActiveResource::Base

    include ActiveModel::Dirty
    extend ActiveModel::Callbacks

    define_model_callbacks :save, :destroy
    define_model_callbacks :initialize, :only => :after

    # @return [RGeoServer::Catalog]
    attr_reader :catalog

    # @param [RGeoServer::Catalog] catalog
    def initialize catalog
      @new = true
      @catalog = catalog
    end

    # Modify or save the resource
    # @param [Hash] options / query parameters
    # @return [RGeoServer::ResourceInfo]
    def save options = {}
      @previously_changed = changes
      @changed_attributes.clear
      run_callbacks :save do
        if new? # need to create
          catalog.add(route, message, options)
        else # exists
          catalog.modify(route, message, options)
        end
        refresh
      end
    end

    # Purge resource from Geoserver Catalog
    # @param [Hash] options
    # @return [RGeoServer::ResourceInfo]
    def delete options = {}
      run_callbacks :destroy do
        catalog.purge(route, options) unless new?
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
      clear!
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
    # mapping object parameters to profile elements
    def self.update_attribute_accessors attributes
      clear_all_code = "def clear!\n"
      attributes.each do |k|
        class_eval %Q{
        def #{k}
          @#{k} ||= profile['#{k}'] || OBJ_DEFAULT_ATTRIBUTES[:#{k}]
        end

        def #{k}= (val)
          #{k}_will_change! unless val == @#{k}
          @#{k} = val
        end
      }
        clear_all_code << "  @#{k} = nil\n"
      end
      clear_all_code << "end\n"
      class_eval clear_all_code
    end
    
    # Retrieve the resource profile as a hash and cache it
    # @return [Hash]
    def profile
      unless @profile
        begin
          self.profile = catalog.search route
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
    # @param [String] format
    # @return [Hash]
    def profile= data, format = :json
      case format
      when :xml
        @profile = profile_xml_to_hash(data)
      when :json
        @profile = profile_json_to_hash(data)
      else
        raise NotImplementedError, "profile= does not support format #{format}"
      end
      @profile.freeze
    end

    # # @abstract
    # # @return [Nokogiri::XML]
    # def profile_xml_to_ng xml
    #   raise NotImplementedError, 'profile_xml_to_ng is abstract method'
    # end

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
