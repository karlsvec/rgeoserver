require 'awesome_print'

c = RGeoServer.catalog
ap({:c => c})

w = c.get_workspace 'druid'
ap({:w => w})
ap({:message => w.message})

w.datastores do |ds|
  ap({:ds => ds})
  ap({:message => ds.message})
end

ds = w.get_datastore 'geoserver_20140205_villagemaps'
ap({:ds => ds})
ap({:message => ds.message})

ds.featuretypes do |ft|
  ap({:ft => ft})
  ap({:message => ft.message})
end