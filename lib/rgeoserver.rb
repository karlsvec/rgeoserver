require 'active_model'
require 'nokogiri'

# RGeoServer is a Ruby client for the GeoServer RESTful Configuration interface.
module RGeoServer
  require 'rgeoserver/version'
  require 'rgeoserver/config'

  autoload :Catalog,              "rgeoserver/catalog"
  autoload :GeoServerUrlHelpers,  "rgeoserver/geoserver_url_helpers"
  autoload :RestApiClient,        "rgeoserver/rest_api_client"

  autoload :Coverage,             "rgeoserver/model/coverage"
  autoload :CoverageStore,        "rgeoserver/model/coveragestore"
  autoload :DataStore,            "rgeoserver/model/datastore"
  autoload :FeatureType,          "rgeoserver/model/featuretype"
  autoload :Layer,                "rgeoserver/model/layer"
  autoload :LayerGroup,           "rgeoserver/model/layergroup"
  autoload :Namespace,            "rgeoserver/model/namespace"
  autoload :ResourceInfo,         "rgeoserver/model/resource"
  autoload :Style,                "rgeoserver/model/style"
  autoload :WmsStore,             "rgeoserver/model/wmsstore"
  autoload :Workspace,            "rgeoserver/model/workspace"

  autoload :BoundingBox,          "rgeoserver/utils/boundingbox"
  autoload :Metadata,             "rgeoserver/utils/metadata"
  autoload :ShapefileInfo,        "rgeoserver/utils/shapefile_info"

  # @return [Catalog] the default GeoServer Catalog instance
  def self.catalog opts = nil
    @@catalog ||= RGeoServer::Catalog.new (opts.nil?? RGeoServer::Config[:geoserver] : opts)
  end

  class RGeoServerError < StandardError
  end

  class GeoServerInvalidRequest < RGeoServerError
  end
  
  class GeoServerArgumentError < RGeoServerError
  end

end
