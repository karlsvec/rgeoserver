ENV['RGEOSERVER_ENVIRONMENT'] ||= 'development'
ENV['RGEOSERVER_CONFIG'] ||= File.join(
  File.dirname(__FILE__), 
  'environments',
  "#{ENV['RGEOSERVER_ENVIRONMENT']}.yml"
)
require 'rgeoserver'