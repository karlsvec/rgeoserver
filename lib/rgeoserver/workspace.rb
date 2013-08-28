module RGeoServer
  class Workspace < Resource
    def datastore name
      ds = DataSource.new @catalog, :name => name
      # ds.load
      ds
    end
  end
end 
