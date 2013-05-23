# -*- encoding : utf-8 -*-

# RGeoServer Batch demo (batch_demo.rb)

#require 'rubygems'
require 'yaml'
require 'rgeoserver'
require 'awesome_print'

#=  Input data. 
# See DATA section

#= Configuration constants
WORKSPACE_NAME = 'rgeoserver_batch'
NAMESPACE = 'urn:rgeoserver_batch'
DATADIR = 'file:///var/geoserver/current/staging' # file:/// is located on the GeoServer

# GeoWebCache configuration
SEED = true
SEED_OPTIONS = {
  :srs => {
    :number => 4326 
  },
  :zoomStart => 1,
  :zoomStop => 7,
  :format => 'image/png',
  :threadCount => 1
}

# Connect to the GS catalog
$c = RGeoServer::Catalog.new

# Obtain a handle to the workspace and clean it up. 
ws = RGeoServer::Workspace.new $c, :name => WORKSPACE_NAME
ws.delete :recurse => true # unless ws.new? # comment or uncomment to start from scratch
ws.save # if ws.new?

# Iterate over all records in YAML file and create stores in the catalog
$layers = YAML::load(DATA)
$layers.each do |id, val|
  name = layername = val['layername'].strip
  format = val['format'].strip

  ap "Layer: #{name} #{format}"
  if format == 'GeoTIFF'
    begin 
      # Create of a coverage store
      cs = RGeoServer::CoverageStore.new $c, :workspace => ws, :name => name
      cs.url = File.join(DATADIR, val['filename'])
      cs.description = val['description'] 
      cs.enabled = 'true'
      cs.data_type = format
      cs.save
      
      # Now create the actual coverage
      cv = RGeoServer::Coverage.new $c, :workspace => ws, :coverage_store => cs, :name => name 
      cv.title = val['title'] 
      cv.keywords = val['keywords']
      cv.metadata_links = val['metadata_links']
      cv.save
      
      # Check if a layer has been created, extract some metadata
      lyr = RGeoServer::Layer.new $c, :name => name
      if !lyr.new? && SEED
        lyr.seed :issue, SEED_OPTIONS
      end
    rescue Exception => e
      $stderr.puts e.inspect
    end

  elsif format == 'Shapefile'
    begin 
      # Create data stores for shapefiles
      ds = RGeoServer::DataStore.new $c, :workspace => ws, :name => name
      ds.connection_parameters = {
        "url" => File.join(DATADIR, val['filename']),
        "namespace" => NAMESPACE
      }
      ds.enabled = 'true'
      ds.save
      
      ft = RGeoServer::FeatureType.new $c, :workspace => ws, :data_store => ds, :name => name 
      ft.title = val['title'] 
      ft.abstract = val['description']
      ft.keywords = val['keywords']
      ft.metadata_links = val['metadata_links']
      ft.save
      
      # Check if a layer has been created and seed it
      lyr = RGeoServer::Layer.new $c, :name => name
      if !lyr.new? && SEED
        lyr.seed :issue, SEED_OPTIONS
      end
      
    rescue Exception => e
      $stderr.puts e, e.backtrace
    end
  else
    raise NotImplementedError, "Unsupported format #{format}"
  end
end

#=DATA
__END__
---
example_vector:
  filename: branner/Precincts_Jan262012_5/Precincts_Jan262012_5.shp
  title: US Precincts, 2008
  layername: Precincts_Jan262012_5
  format: Shapefile
  description: This is a dataset developed by Prof. Jonathan Rodden at Stanford University showing precinct polygon data for the United States for the year 2008.
  keywords: [vector, precinct, political, US, voting, 2008, elections, "United States\\@language=en\\;\\@vocabulary=ISOTC211/19115:place\\;"]
  metadata_links: [{
    metadataType: TC211, 
    content: "http://purl.stanford.edu/catalog/aa111aa1111/iso19139.xml"}] 
  metadata:
    druid: aa111aa1111
    publisher: Jonathan Rodden, Stanford University

example_vector_broken_projection:
  filename: branner/urban2050_ca/urban2050_ca.shp
  title: Projected Urban Growth scenarios for 2050
  layername: urban2050_ca
  format: Shapefile
  description: By 2020, most forecasters agree, California will be home to between 43 and 46 million residents-up 
    from 35 million today. Beyond 2020 the size of California's population is less certain.
  keywords: [vector, urban, landis, "California\\@language=en\\;\\@vocabulary=ISOTC211/19115:place\\;"]
  metadata_links: [{
    metadataType: TC211, 
    content: "http://purl.stanford.edu/catalog/aa111aa1111/iso19139.xml"}] 
  metadata:
    druid: aa111aa1111
    publisher: Landis

example_raster:
  filename: rumsey/g3881015alpha.tif
  title: U.S. Civil War battle of Antietam, 1867
  layername: antietam_1867
  format: GeoTIFF
  description: Map shows the U.S. Civil War battle of Antietam.  It indicates fortifications,
    roads, railroads, houses, names of residents, fences, drainage, vegetation, and
    relief by hachures.
  keywords: [civil war, battles]
  metadata_links: [{
    metadataType: TC211, 
    content: "http://purl.stanford.edu/catalog/bb222bb2222/iso19139.xml"}] 
  metadata:
    druid: bb222bb2222
    publisher: Unknown

