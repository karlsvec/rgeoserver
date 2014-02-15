require 'active_resource'
require 'restclient'

class Base < ActiveResource::Base
  self.site = "http://localhost:8080/geoserver/rest"
  self.user = 'admin'
  self.password = 'admin123'
end

class Datastore < Base
  schema do
    string :name
    boolean :enabled
  end
end

class Workspace < Base
  schema do
    string :name
    boolean :enabled
  end
  has_many :datastores
end

w = Workspace.find('druid')
w.id
w.name
w.enabled
w.dataStores
w.coverageStores
w.wmsStores

site = RestClient::Resource.new("http://localhost:8080/geoserver/rest", :user => 'admin', :password => 'admin123', :headers => {:accept => 'application/json'})
w = site['workspaces']
w.get
druid = w['druid']
druid.get
d = druid['datastores']
d.get