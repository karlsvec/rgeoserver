require 'spec_helper'

describe RGeoServer::Workspace do 
  before :all do
    @w = RGeoServer::Workspace.find(:druid)
    ap({:druid => @w})
  end
       
  it 'name attribute' do
    @w.name.should == 'druid'
  end

  it 'data stores attribute' do
    @w.dataStores.should == 'http://kurma-podd1.stanford.edu/geoserver/rest/workspaces/druid/datastores.json'
  end
end 
