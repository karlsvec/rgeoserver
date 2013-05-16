$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'rgeoserver'
require 'awesome_print'

RestClient.log = '/tmp/restclient.log'
@config = RGeoServer::Config
ap @config
@c = RGeoServer.Catalog.new
ap @c
@w = @c.get_workspace 'druid'
ap @w

@w.data_stores do |ds|
  ds.featuretypes do |ft|
    ap [ft, ft.name, ft.message]
  end
  ap [ds, ds.name]
end
