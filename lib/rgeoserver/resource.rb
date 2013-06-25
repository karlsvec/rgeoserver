module RGeoServer

  class ResourceInfo

    include ActiveModel::Dirty
    extend ActiveModel::Callbacks

    define_model_callbacks :save, :destroy
    define_model_callbacks :initialize, :only => :after

    attr_accessor :catalog

    # mapping object parameters to profile elements
    OBJ_ATTRIBUTES = {
        :enabled => 'enabled'
    }
    OBJ_DEFAULT_ATTRIBUTES = {
        :enabled => 'true'
    }

    define_attribute_methods OBJ_ATTRIBUTES.keys

    def self.update_attribute_accessors attributes
      attributes.each do |attribute, profile_name|
        class_eval <<-RUBY
          def #{attribute.to_s}
            @#{attribute} || profile['#{profile_name.to_s}'] || OBJ_DEFAULT_ATTRIBUTES[:#{attribute}]
          end

          def #{attribute.to_s}= val
            #{attribute.to_s}_will_change! unless val == #{attribute.to_s}
            @#{attribute.to_s} = val
          end
        RUBY
      end
    end

    # Generic object construction iterator
    # @param [RGeoServer::ResourceInfo.class] klass
    # @param [RGeoServer::Catalog] catalog
    # @param [Array<String>] names
    # @param [Hash] options
    # @param [bool] check_remote if already exists in catalog and cache it
    # @yield [RGeoServer::ResourceInfo,klass] optional
    def self.list klass, catalog, names, options = {}, check_remote = false
      raise ArgumentError, "Names required" if names.nil?
      names = [names] unless names.is_a? Array
      l = []
      names.each do |name|
        obj = klass.new catalog, options.merge(:name => name)
        obj.new? if check_remote
        if block_given?
          yield obj
        else
          l << obj
        end
      end
      l unless block_given?
    end

    def initialize catalog = nil
      @new = true
      @catalog = catalog
    end

    def to_s
      "#{self.class.name}: #{name} (#{new?}) on #{catalog}"
    end

    def create_method
      :post
    end

    def update_method
      :put
    end

    # We pass the old name "name_route" in case the name of the resource is being edited
    # Child classes should implement this
    def update_params name_route = name
      { self.class.resource_name.downcase.to_sym => name_route }
    end

    # Modify or save the resource
    # @param [Hash] options / query parameters
    # @return [RGeoServer::ResourceInfo]
    def save options = {}
      @previously_changed = changes
      @changed_attributes.clear
      run_callbacks :save do
        name_route = name
        update = false
        unless @previously_changed[:name].nil?
          old_name, new_name = @previously_changed[:name]
          name_route = old_name if old_name != new_name
          update = true
        end
        if not update and new?
          if self.respond_to?(:create_route)
            raise 'Resource cannot be created directly' if create_route.nil?
            route = create_route
          else
            route = { @route => nil }
          end

          options = create_options.merge(options) if self.respond_to?(:create_options)
          @catalog.add(route, message, create_method, options)
          clear
        else
          options = update_params(name_route).merge(options)
          route = { @route => name_route }
          @catalog.modify(route, message, update_method, options) #unless changes.empty?
        end
        self
      end
    end

    # Purge resource from Geoserver Catalog
    # @param [Hash] options
    # @return [RGeoServer::ResourceInfo] `self`
    def delete options = {}
      run_callbacks :destroy do
        @catalog.purge({ @route => @name }, options) unless new?
        clear
        self
      end
    end

    # Check if this resource already exists
    # @return [Boolean]
    def new?
      profile
      @new
    end

    def clear
      @profile = nil
      @changed_attributes = {}
    end

    def refresh
      clear
      profile
      self
    end

    # Retrieve the resource profile as a hash and cache it
    # @return [Hash]
    def profile
      unless @profile
        begin
          self.profile = @catalog.search @route => @name # use profile= method
          @new = false
        rescue RestClient::ResourceNotFound # The resource is new
          @profile = {}
          @new = true
        end
        @profile.freeze unless @profile.frozen?
      end
      @profile
    end

    def profile= profile_xml
      @profile = profile_xml_to_hash(profile_xml)
      @profile.freeze
    end

    def profile_xml_to_ng profile_xml
      Nokogiri::XML(profile_xml).xpath(self.class.member_xpath)
    end

    def profile_xml_to_hash profile_xml
      raise NotImplementedError, 'profile_xml_to_hash is abstract method'
    end

  end
end
