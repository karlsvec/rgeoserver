require 'rgeoserver'

c = RGeoServer::Catalog.new
w = c.get_default_workspace
ds = w.data_stores
ds.first.profile
