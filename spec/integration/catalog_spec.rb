require 'spec_helper'
require 'awesome_print'

describe RGeoServer::Catalog do

  before(:each) do
    @c = RGeoServer::Catalog.new
  end
    
  describe "workspace" do
    it "#workspaces" do
      @c.workspaces do |w|
        w.name.length.should > 0
      end
    end    
  end

  describe "layers" do
    it "#layers" do
      @c.layers do |l|
        l.name.length.should > 0
      end
    end    
  end

  describe "styles" do
    it "#styles" do
      @c.styles do |s|
        s.name.length.should > 0
      end
    end    
  end

end 
