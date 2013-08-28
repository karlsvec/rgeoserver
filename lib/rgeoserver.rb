require 'active_resource'

# RGeoServer is a Ruby client for GeoServer's REST catalog interfaces, 
# and provides a Rails model abstraction for GeoServer resources
module RGeoServer
  VERSION = File.read(File.join(File.dirname(__FILE__), '..', 'VERSION')).to_s.strip
  
  # mandatory loads
  require 'rgeoserver/config'
  # require 'rgeoserver/resource'
  # require 'rgeoserver/catalog'
  # require 'rgeoserver/workspace'
  # require 'rgeoserver/datastore'
  # require 'rgeoserver/featuretype'
  # require 'rgeoserver/layer'
  # require 'rgeoserver/style'
  
  class Catalog
    attr_reader :config, :site, :user, :format

    # @param [OrderedHash] options, if nil, uses RGeoServer::Config[:geoserver] 
    # loaded from $RGEOSERVER_CONFIG or config/defaults.yml
    #   :url defaults to 'http://localhost:8080/geoserver/rest'
    #   :user
    #   :password
    #   :format either 'xml' or 'json'
    def initialize options = nil
      @config = options || RGeoServer::Config[:geoserver]
      unless @config.include?(:url)
        raise ArgumentError, "Catalog: Requires :url option: #{@config}"
      end
      @site = @config[:url] || 'http://localhost:8080/geoserver/rest'
      @user = @config[:user]
      @password = @config[:password]
      @format = @config[:format] || 'xml'
    end

    def to_s
      "Catalog: #{@user}@#{@site}"
    end
        
  end
  
  class Workspace < ActiveResource::Base
    self.site = "http://admin:admin123@kurma-podd1.stanford.edu/geoserver/rest"
    self.element_name = "workspaces"
    # has_many :datastores
  end
  

  # @return [Catalog] the default GeoServer Catalog instance
  def self.catalog
    @@catalog ||= RGeoServer::Catalog.new RGeoServer::Config[:geoserver]
  end

  # General error
  class RGeoServerError < StandardError; end
end
