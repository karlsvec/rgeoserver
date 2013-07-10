require 'confstruct/configuration'
require 'yaml'

# Uses $RGEOSERVER_CONFIG from environment, or config/defaults.yml 
# using Confstruct file format.
# @see https://rubygems.org/gems/confstruct 
module RGeoServer
  Config = Confstruct::Configuration.new(
    YAML.load(
      File.read(
        ENV['RGEOSERVER_CONFIG'] ||
        File.join(File.dirname(__FILE__), '..', '..', 'config', 'defaults.yml')
      )
    )
  )
end


