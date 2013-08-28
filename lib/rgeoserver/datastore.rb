module RGeoServer
  class DataStore < Resource
    # self.prefix = self.site.path + '/workspaces/druid/'
    # self.element_name = 'datastores'
    # 
    # schema do
    #   string :name
    #   string :description
    #   boolean :enabled
    # end
    
    def feature_type name
      ft = FeatureType.new @catalog, :name => name
      # ft.load
      ft
    end
  end
end
