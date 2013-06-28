require 'logger'
require 'active_resource'

ActiveResource::Base.logger = Logger.new(STDOUT)
ActiveResource::Base.logger.level = Logger::DEBUG

# require 'net/http'
# module Net
#   class HTTP
#     class << self
#       alias_method :__new__, :new
#       def new(*args, &blk)
#         instance = __new__(*args, &blk)
#         instance.set_debug_output($stderr)
#         instance
#       end
#     end
#   end
# end

require 'spec_helper'

describe RGeoServer::Workspace do
  it "#new" do
    r = RGeoServer::Workspace.new :name => 'druid'
    r.attributes['name'].should == 'druid'
  end
  
  it "#find" do
    r = RGeoServer::Workspace.find('druid')
    r.attributes['name'].should == 'druid'
    r.attributes['dataStores'].nil?.should == false
  end
  
  it "#all" do
    RGeoServer::Workspace.all do |w|
      # ap w
    end
  end
end

describe RGeoServer::DataStore do
  it "#find" do
    r = RGeoServer::DataStore.find('df559hb2469')
    r.attributes['type'].should == 'Shapefile'
    ap r.attributes
    ap r.name
    ap r.description
    ap r.enabled
  end

  it "#all" do
    RGeoServer::DataStore.all do |ds|
      ap ds
    end
  end
end