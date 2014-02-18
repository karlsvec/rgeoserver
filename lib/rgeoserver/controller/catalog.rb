module RGeoServer
  # This class represents the main class of the data model, and provides all REST APIs to GeoServer.
  # @see http://geoserver.org/display/GEOS/Catalog+Design
  # @see http://docs.geoserver.org/stable/en/user/rest/api/
  class Catalog
    include RGeoServer::RestApiClient

    # @return [Hash]
    attr_reader :config

    # @param [OrderedHash] options if nil, uses RGeoServer::Config\[:geoserver] loaded from 
    #     \$RGEOSERVER_CONFIG or config/defaults.yml
    # @option options [String] :url
    # @option options [String] :user
    # @option options [String] :password
    # @option options [String] :logfile
    # @raise [RGeoServer::ArgumentError]
    def initialize options = nil
      @config = options || RGeoServer::Config[:geoserver]
      unless config.include?(:url)
        raise RGeoServer::ArgumentError, "Catalog: Requires :url option: #{config}"
      end
      RestClient.log = config[:logfile] || nil
    end

    # @return [String]
    def to_s
      "#{self.class}: #{config[:url]}"
    end

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

    # @yield [RGeoServer::Layer]
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
