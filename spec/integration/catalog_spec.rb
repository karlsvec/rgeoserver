require 'spec_helper'
require 'awesome_print'
describe RGeoServer::GeoServerUrlHelpers do

  before(:each) do
    @c = RGeoServer::Catalog.new
    @w = @c.get_workspace 'druid'
    @w_default = @c.get_default_workspace  
    ap({ :catalog => @c, :workspace_druid => @w, :workspace_default => @w_default })
  end
  
  describe "Init" do
    it "workspaces" do
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
    it "#get_workspaces" do
      @w_all = @c.get_workspaces
      ap({ :w_all => @w_all })
    end
    
  end
  
  describe "DataStore" do
    it "#data_stores" do
      @w_ds = @w.data_stores {|ds| ds}
      ap({ :w_ds => @w_ds })
    end
  end

end 
