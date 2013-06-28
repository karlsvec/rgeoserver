module RGeoServer
  class DataStore < GeoServerResource
    self.prefix = self.site.path + '/workspaces/druid/'
    self.element_name = 'datastores'
    
    schema do
      string :name
      string :description
      boolean :enabled
    end
  end
end
