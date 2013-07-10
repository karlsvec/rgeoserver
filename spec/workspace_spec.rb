require 'spec_helper'

describe RGeoServer::Workspace do

  before(:all) do
    @c = RGeoServer.catalog
  end
  
  it 'catalog' do
    w = @c.workspace 'alpha'
    w.catalog.should == @c
  end
  
  it 'names' do
    %w{alpha bravo charlie delta}.each do |k|
      w = @c.workspace k
      w.is_a?(RGeoServer::Workspace).should == true
      w.name.should == k
    end
  end
  
end 
