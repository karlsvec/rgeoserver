require 'confstruct'
require 'confstruct/configuration'
require 'yaml'

module RGeoServer
  # Uses config/defaults.yml or $RGEOSERVER_CONFIG from environment
  # @see https://rubygems.org/gems/confstruct for details on file format
  Config = Confstruct::Configuration.new(
  YAML.load(
    File.read(
      ENV['RGEOSERVER_CONFIG'] ||
      File.join(File.dirname(__FILE__), '..', '..', 'config', 'defaults.yml')
      )
    )
  )
end
