require 'confstruct'
require 'confstruct/configuration'
require 'yaml'

# Uses config/defaults.yml or $RGEOSERVER_CONFIG from environment
# See https://rubygems.org/gems/confstruct for details on file format
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


