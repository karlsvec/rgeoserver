require 'spec_helper'
require 'awesome_print'

describe RGeoServer::GeoServerUrlHelpers do

  before(:each) do
    @c = RGeoServer::Catalog.new
    @w = @c.get_workspace 'druid'
    @w_default = @c.get_default_workspace  
    ap({ :catalog => @c, :workspace_druid => @w, :workspace_default => @w_default }) if $DEBUG
  end
  
  describe "Init" do
    it "catalog" do
      @c.config.include?(:url).should == true
      @c.headers.include?(:content_type).should == true
    end
    
    it "workspace" do
      @w.name.should == 'druid'
      @w_default.name.should == @w.name
    end
  end
  
  describe "#url_for" do
    it "simple" do
      @c.respond_to?('url_for').should == true      
    end
  end
  
  describe "Workspace" do
    it "#get_workspaces as array" do
      @w_all = @c.get_workspaces
      @w_all.size.should > 0
    end
    
    it "#get_workspaces as block" do
      @c.get_workspaces do |w|
        w.name.length.should > 0
      end
    end
  end

  describe "Layers" do
    it "#get_layers" do
      @c.get_layers.size.should > 0
      @c.get_layers.each do |l|
        # ap l.resource
      end
    end
  end
  
  describe "DataStore" do
    it "#get_data_stores" do
      @c.get_data_stores.size.should > 0
    end
  end

  describe "CoverageStore" do
    it "#get_coverage_stores" do
      @c.get_coverage_stores.size.should > 0
    end
  end

  describe "WMSStore" do
    it "#get_wms_stores" do
      @c.get_wms_stores.size.should > 0
    end
  end
  
end 
