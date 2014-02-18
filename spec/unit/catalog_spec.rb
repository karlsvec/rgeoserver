require 'spec_helper'
require 'awesome_print'

describe RGeoServer::Catalog do

  before(:each) do
    @c = RGeoServer::Catalog.new
    @w = @c.get_workspace 'druid'
    @w_default = @c.get_workspace  
    ap({ :catalog => @c, :workspace_druid => @w, :workspace_default => @w_default }) if $DEBUG
  end
  
  describe "init" do
    it "config" do
      @c.config.include?(:url).should == true
      @c.headers.include?(:content_type).should == true
    end
  end
  
  describe "#url_for" do
    it "simple" do
      @c.respond_to?('url_for').should == true      
    end
  end
  
  describe "workspace" do
    it "#get_workspace" do
      @w.name.should == 'druid'
      @w_default.name.should == 'default'
    end    
  end

end 
