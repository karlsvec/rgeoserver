require 'confstruct/configuration'

# Uses config/defaults.yml or $RGEOSERVER_CONFIG from environment
# See https://rubygems.org/gems/confstruct for details on file format
module RGeoServer
  def self.Config
    @@Config ||= Confstruct::Configuration.new(
      YAML.load(
        File.read(
          ENV['RGEOSERVER_CONFIG'] or
          File.join(File.dirname(__FILE__), '..', '..', 'config', 'defaults.yml'))))
  end
end


