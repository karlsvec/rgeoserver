require 'awesome_print'

c = RGeoServer.catalog
ap({:c => c})

w = c.get_workspace 'druid'
ap({:w => w})
ap({:message => ActiveSupport::JSON.decode(w.message)})

w.datastores do |ds|
  ap({:ds => ds})
  ap({:message => ActiveSupport::JSON.decode(ds.message)})
end

ds = w.get_datastore 'geoserver_20140205_villagemaps'
ap({:ds => ds})
ap({:message => ActiveSupport::JSON.decode(ds.message)})

ds.featuretypes do |ft|
  ap({:ft => ft})
  ap({:message => ActiveSupport::JSON.decode(ft.message)})
end

w.coveragestores do |cs|
  ap({:cs => cs})
  ap({:message => ActiveSupport::JSON.decode(cs.message)})
end

cs = w.get_coveragestore 'nw926np8508'
ap({:cs => cs})
ap({:message => ActiveSupport::JSON.decode(cs.message)})

cs.coverages do |c|
  ap({:c => c})
  ap({:message => ActiveSupport::JSON.decode(c.message)})
end

