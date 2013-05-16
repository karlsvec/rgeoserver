require 'confstruct/configuration'

# Uses config/defaults.yml or config/$RGEOSERVER_CONFIG from environment
# See https://rubygems.org/gems/confstruct for details on file format
module RGeoServer
  Config = Confstruct::Configuration.new(
    YAML.load(
      File.read(
        File.join(File.dirname(__FILE__), '..', '..', 'config', (ENV['RGEOSERVER_CONFIG'] ||= 'defaults.yml')))))
end


