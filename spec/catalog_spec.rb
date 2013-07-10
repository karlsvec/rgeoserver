require 'spec_helper'

describe RGeoServer::Catalog do

  before(:all) do
    @c = RGeoServer::Catalog.new
  end

  it "#methods" do
    @c.respond_to?(:config).should == true
    @c.respond_to?(:workspace).should == true
    @c.respond_to?(:default_workspace).should == true
    @c.respond_to?(:layer).should == true
    @c.respond_to?(:style).should == true
  end
  
end 
