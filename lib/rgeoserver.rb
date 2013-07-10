# require 'active_model'
# require 'active_resource'
# require 'yaml'
# require 'confstruct'
# require 'restclient'
# require 'nokogiri'
# require 'time'

# require 'logger'
# $logger = Logger.new(STDERR)
# $logger.level = Logger::DEBUG

# RGeoServer is a Ruby client for GeoServer's REST catalog interfaces, 
# and provides a Rails model abstraction for GeoServer resources
module RGeoServer
  # mandatory loads
  require 'rgeoserver/version'
  require 'rgeoserver/config'
  require 'rgeoserver/catalog'

  # lazy loads
  autoload :Layer,      'rgeoserver/layer'
  autoload :Resource,   'rgeoserver/resource'
  autoload :Style,      'rgeoserver/style'
  autoload :Workspace,  'rgeoserver/workspace'
  
  # autoload :Coverage,             'rgeoserver/coverage'
  # autoload :CoverageStore,        'rgeoserver/coveragestore'
  # autoload :DataStore,            'rgeoserver/datastore'
  # autoload :FeatureType,          'rgeoserver/featuretype'
  # autoload :GeoServerUrlHelpers,  'rgeoserver/geoserver_url_helpers'
  # autoload :LayerGroup,           'rgeoserver/layergroup'
  # autoload :Namespace,            'rgeoserver/namespace'
  # autoload :ResourceInfo,         'rgeoserver/resource'
  # autoload :RestApiClient,        'rgeoserver/rest_api_client'
  # autoload :WmsStore,             'rgeoserver/wmsstore'

  # autoload :BoundingBox,          'rgeoserver/utils/boundingbox'
  # autoload :Metadata,             'rgeoserver/utils/metadata'
  # autoload :ShapefileInfo,        'rgeoserver/utils/shapefile_info'
  
  # @return [Catalog] the default GeoServer Catalog instance
  def self.catalog
    @@catalog ||= RGeoServer::Catalog.new RGeoServer::Config[:geoserver]
  end

  # General error
  class RGeoServerError < StandardError; end
  # REST API error
  class GeoServerInvalidRequest < RGeoServerError; end
  # General argument or type mismatch error
  class GeoServerArgumentError < RGeoServerError; end

end
