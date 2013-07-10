require 'spec_helper'

describe RGeoServer::Catalog do

  before(:all) do
    @c = RGeoServer.catalog # default instance
  end

  it "prototype" do
    @c.respond_to?(:config).should == true
    @c.respond_to?(:workspace).should == true
    @c.respond_to?(:default_workspace).should == true
    @c.respond_to?(:layer).should == true
    @c.respond_to?(:style).should == true
    @c.respond_to?(:reload).should == true
    @c.respond_to?(:reset).should == true
  end 
end 
