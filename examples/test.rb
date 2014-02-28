require 'awesome_print'
require 'active_support'

class String
  def from_json
    ActiveSupport::JSON.decode(self.to_s)
  end
end

'{"hi":"hello"}'.from_json

c = RGeoServer.catalog
ap({:c => c})

w = c.get_workspace 'druid'
ap({:w => w})
ap({:message => w.message.from_json})

w.datastores do |ds|
  ap({:ds => ds})
  ap({:message => ds.message.from_json})
end

ds = w.get_datastore 'geoserver_20140205_villagemaps'
ap({:ds => ds})
ap({:message => json_decode(ds.message)})

ds.featuretypes do |ft|
  ap({:ft => ft})
  ap({:message => json_decode(ft.message)})
end

w.coveragestores do |cs|
  ap({:cs => cs})
  ap({:message => json_decode(cs.message)})
end

cs = w.get_coveragestore 'nw926np8508'
ap({:cs => cs})
ap({:message => json_decode(cs.message)})

cs.coverages do |cv|
  ap({:cv => cv})
  ap({:message => json_decode(cv.message)})
end

