module RGeoServer
  # This class represents the main class of the data model, and provides all REST APIs to GeoServer.
  # @see http://geoserver.org/display/GEOS/Catalog+Design
  # @see http://docs.geoserver.org/stable/en/user/rest/api/

  class Catalog
    include RGeoServer::RestApiClient

    attr_reader :config

    # @param [OrderedHash] options if nil, uses RGeoServer::Config[:geoserver] loaded from $RGEOSERVER_CONFIG or config/defaults.yml
    # options :url
    # options :user
    # options :password
    def initialize options = nil
      @config = options || RGeoServer::Config[:geoserver]
      unless config.include?(:url)
        raise GeoServerArgumentError, "Catalog: Requires :url option: #{config}"
      end
      RestClient.log = config[:logfile] || nil
    end

    def to_s
      "Catalog: #{config[:url]}"
    end

    #= Workspaces

    # @yield [RGeoServer::Workspace]
    def workspaces
      doc = Nokogiri::XML(search :workspaces => nil)
      doc.xpath('/workspaces/workspace/name/text()').each do |name|
        yield get_workspace(name)
      end
    end

    # @param [String] name
    # @return [RGeoServer::Workspace]
    def get_workspace name
      Workspace.new self, :name => name
    end

    #= Layers

    # @return [RGeoServer::Layer]
    def layers
      doc = Nokogiri::XML(self.search :layers => nil)
      doc.xpath('/layers/layer/name/text()').each do |name|
        yield get_layer(name.to_s.strip)
      end
    end

    # @param [String] name
    # @return [RGeoServer::Layer]
    def get_layer name
      Layer.new self, :name => name
    end

    #= Styles (SLD Style Layer Descriptor)

    # @yield [RGeoServer::Style]
    def styles
      doc = Nokogiri::XML(search :styles => nil)
      doc.xpath('/styles/style/name/text()').each do |name| 
        yield get_style(name.to_s.strip)
      end
    end

    # @param [String] name
    # @return [RGeoServer::Style]
    def get_style name
      Style.new self, :name => name
    end

    #= Configuration reloading
    # Reloads the catalog and configuration from disk. This operation is used to reload GeoServer in cases where an external tool has modified the on disk configuration. This operation will also force GeoServer to drop any internal caches and reconnect to all data stores.
    def reload
      do_url 'reload', :put
    end

    #= Resource reset
    # Resets all store/raster/schema caches and starts fresh. This operation is used to force GeoServer to drop all caches and stores and reconnect fresh to each of them first time they are needed by a request. This is useful in case the stores themselves cache some information about the data structures they manage that changed in the meantime.
    def reset
      do_url 'reset', :put
    end

  end

end
