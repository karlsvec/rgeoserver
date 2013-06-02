require 'active_model'
require 'yaml'
require 'confstruct'
require 'restclient'
require 'nokogiri'
require 'time'

# RGeoServer is a Ruby client for the GeoServer RESTful Configuration interface.
module RGeoServer
  require 'rgeoserver/version'
  
  autoload :Config, "rgeoserver/config"
  autoload :Catalog, "rgeoserver/catalog"
  autoload :RestApiClient, "rgeoserver/rest_api_client"
  autoload :GeoServerUrlHelpers, "rgeoserver/geoserver_url_helpers"
  autoload :ResourceInfo, "rgeoserver/resource"
  autoload :Namespace, "rgeoserver/namespace"
  autoload :Workspace, "rgeoserver/workspace"
  autoload :FeatureType, "rgeoserver/featuretype"
  autoload :Coverage, "rgeoserver/coverage"
  autoload :DataStore, "rgeoserver/datastore"
  autoload :CoverageStore, "rgeoserver/coveragestore"
  autoload :WmsStore, "rgeoserver/wmsstore"
  autoload :Style, "rgeoserver/style"
  autoload :Layer, "rgeoserver/layer"
  autoload :LayerGroup, "rgeoserver/layergroup"

  autoload :BoundingBox, "rgeoserver/utils/boundingbox"
  autoload :ShapefileInfo, "rgeoserver/utils/shapefile_info"
  autoload :Metadata, "rgeoserver/utils/metadata"

  # @return the default GeoServer Catalog instance
  def self.catalog
    @@catalog ||= Catalog.new RGeoServer::config[:geoserver]
  end

  class RGeoServerError < StandardError
  end

  class GeoServerInvalidRequest < RGeoServerError
  end

end
