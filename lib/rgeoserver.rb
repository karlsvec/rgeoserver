require 'active_model'
require 'active_resource'
require 'nokogiri'

# RGeoServer is a Ruby client for the GeoServer RESTful Configuration interface.
module RGeoServer
  require 'rgeoserver/version'
  require 'rgeoserver/config'

  autoload :Catalog,              'rgeoserver/controller/catalog'
  autoload :GeoServerUrlHelpers,  'rgeoserver/controller/geoserver_url_helpers'
  autoload :RestApiClient,        'rgeoserver/controller/rest_api_client'

  autoload :Coverage,             'rgeoserver/model/coverage'
  autoload :CoverageStore,        'rgeoserver/model/coveragestore'
  autoload :DataStore,            'rgeoserver/model/datastore'
  autoload :FeatureType,          'rgeoserver/model/featuretype'
  autoload :Layer,                'rgeoserver/model/layer'
  autoload :LayerGroup,           'rgeoserver/model/layergroup'
  autoload :Namespace,            'rgeoserver/model/namespace'
  autoload :ResourceInfo,         'rgeoserver/model/resource'
  autoload :Style,                'rgeoserver/model/style'
  autoload :WmsStore,             'rgeoserver/model/wmsstore'
  autoload :Workspace,            'rgeoserver/model/workspace'

  autoload :BoundingBox,          'rgeoserver/utils/boundingbox'
  autoload :Metadata,             'rgeoserver/utils/metadata'
  autoload :ShapefileInfo,        'rgeoserver/utils/shapefile_info'

  # @return [Catalog] the default GeoServer Catalog instance
  def self.catalog opts = nil
    @@catalog ||= RGeoServer::Catalog.new(opts || RGeoServer::Config[:geoserver])
  end

  # generic error for module
  class RGeoServer::Error < StandardError
  end

  # client/server error
  class RGeoServer::InvalidRequest < RGeoServer::Error
  end
  
  # API error
  class RGeoServer::ArgumentError < RGeoServer::Error
  end

end
