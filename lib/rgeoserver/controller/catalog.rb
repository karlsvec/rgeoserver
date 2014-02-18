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
        raise RGeoServer::ArgumentError, "Catalog: Requires :url option: #{config}"
      end
      RestClient.log = config[:logfile] || nil
    end

    def to_s
      "#{self.class}: #{config[:url]}"
    end

    #= Workspaces

    # @yield [RGeoServer::Workspace]
    def workspaces
      doc = Nokogiri::XML(search :workspaces => nil)
      doc.xpath('/workspaces/workspace/name').each do |n|
        yield get_workspace(n.text.strip)
      end
    end

    # @param [String] name
    # @return [RGeoServer::Workspace]
    def get_workspace name = 'default'
      Workspace.new self, :name => name
    end

    #= Layers

    # @return [RGeoServer::Layer]
    def layers
      doc = Nokogiri::XML(self.search :layers => nil)
      doc.xpath('/layers/layer/name').each do |n|
        yield get_layer(n.text.strip)
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
      doc.xpath('/styles/style/name').each do |n| 
        yield get_style(n.text.strip)
      end
    end

    # @param [String] name
    # @return [RGeoServer::Style]
    def get_style name
      Style.new self, :name => name
    end
  end
end
