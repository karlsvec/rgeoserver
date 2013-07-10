require 'nokogiri'

module RGeoServer
  # This class represents the main class of the data model, 
  # and provides all REST APIs to GeoServer.
  #
  # @see http://geoserver.org/display/GEOS/Catalog+Design
  # @see http://docs.geoserver.org/stable/en/user/rest/api/
  class Catalog
    # include RGeoServer::RestApiClient
    # require 'restclient'
    
    def search options = nil
      raise NotImplementedError
    end

    attr_reader :config

    # @param [OrderedHash] options, if nil, uses RGeoServer::Config[:geoserver] 
    # loaded from $RGEOSERVER_CONFIG or config/defaults.yml
    # @param [String] options :url
    # @param [String] options :user
    # @param [String] options :password
    def initialize options = nil
      @config = options || RGeoServer::Config[:geoserver]
      unless config.include?(:url)
        raise ArgumentError, "Catalog: Requires :url option: #{config}"
      end
      # RestClient.log = config[:logfile] || nil
    end

    def to_s
      "Catalog: #{config[:url]}"
    end

    # @param name [String] name
    # @return [RGeoServer::Workspace]
    def workspace name
      w = Workspace.new self, :name => name
      # w.load
      w
    end

    # @param name [String] name
    # @return [RGeoServer::Layer]
    def layer name
      l = Layer.new self, :name => name
      # l.load
      l
    end

    # @param name [String] name
    # @return [RGeoServer::Style]
    def style name
      s = Style.new self, :name => name
      # s.load
      s
    end

    # @return [RGeoServer::Workspace] catalog.workspace('default')
    def default_workspace
      workspace 'default'
    end

    # Assign default workspace
    # @param [String] workspace name
    def default_workspace= name
      unless name.is_a? String
        raise TypeError, 'Workspace #{name} must be a String'
      end
      w = Workspace.new self, :name => 'default'
      w.name = name.to_s # This creates a new workspace if name is new
      w.save
      w
    end

    #= Configuration reloading
    # Reloads the catalog and configuration from disk. This operation is used to reload GeoServer in cases where an external tool has modified the on disk configuration. This operation will also force GeoServer to drop any internal caches and reconnect to all data stores.
    def reload
      # do_url 'reload', :put
    end

    #= Resource reset
    # Resets all store/raster/schema caches and starts fresh. This operation is used to force GeoServer to drop all caches and stores and reconnect fresh to each of them first time they are needed by a request. This is useful in case the stores themselves cache some information about the data structures they manage that changed in the meantime.
    def reset
      # do_url 'reset', :put
    end
    
    private
    # List available workspaces, layers, or styles
    # @yield [Workspace,Layer,Style]
    def _each klass = Workspace
      doc = Nokogiri::XML(
          case klass # dispatch search
          when Workspace
            search :workspaces => nil
          when Layer
            search :layers => nil
          when Style
            search :styles => nil
          else
            raise ArgumentError, "Invalid klass for each method: #{klass}"
          end
      )
      doc.xpath(klass.root_xpath + '/name/text()').each do |name|
        yield klass.new self, :name => name.to_s.strip
      end
    end
    
  end
end
