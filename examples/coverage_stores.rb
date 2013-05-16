
require 'rgeoserver'

layers = {
  'south_america_1787' => {
    'url' => 'file:///geo_data/rumsey/g0411047.tif',
    'description' => "Map of South America by D'Anville",
    'type' => 'GeoTIFF'
   },
  'city_of_san_francisco_1859' => {
    'url' => 'file:///geo_data/rumsey/g1030000alpha.tif',
    'description' => 'Map of San Francisco by the U.S. Coast Survey, with detail of the unsettled lands',
    'type' => 'GeoTIFF'
  }
}

(1..7).each do |cat_id|
  cat = RGeoServer::Catalog.new
  ws = cat.get_default_workspace
  cat.list(RGeoServer::CoverageStore, layers.keys, :workspace => ws) do |cs|
    cs.url = layers[cs.name]['url']
    cs.data_type = layers[cs.name]['type']
    cs.enabled = 'true'
    cs.save
    # Create the corresponding layer
    c = RGeoServer::Coverage.new cat, :workspace => ws, :coverage_store => cs, :name => cs.name 
    c.title = cs_name.gsub('_',' ').titleize
    c.abstract = layers[cs.name]['description']
    c.save
    # Seed the tile cache
    l = RGeoServer::Layer.new cat, :name => cs.name
    l.seed :issue, {
      :srs => {
        :number => 4326
      },
      :zoomStart => 1,
      :zoomStop => 10,
      :format => 'image/png',
      :threadCount => 1
    }
  end
end
