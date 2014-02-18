require 'spec_helper'
require 'awesome_print'

describe RGeoServer::Catalog do

  before(:each) do
    @c = RGeoServer::Catalog.new
    @w = @c.get_workspace 'abc'
    @w_default = @c.get_workspace  
    ap({ :catalog => @c, :workspace_druid => @w, :workspace_default => @w_default }) if $DEBUG
  end
  
  describe "init" do
    it "config" do
      @c.config.include?(:url).should == true
      @c.headers[:accept].should == 'application/json'
      @c.headers[:content_type].should == 'application/json'
    end
  end
  
  describe "#url_for" do
    it "simple" do
      @c.respond_to?(:url_for).should == true      
    end
  end

  describe "#add" do
    it "simple" do
      @c.respond_to?(:add).should == true      
    end
  end

  describe "#client" do
    it "simple" do
      @c.respond_to?(:client).should == true      
      @c.respond_to?(:gwc_client).should == true      
    end
  end

  describe "#modify" do
    it "simple" do
      @c.respond_to?(:modify).should == true      
    end
  end

  describe "#purge" do
    it "simple" do
      @c.respond_to?(:purge).should == true      
    end
  end

  describe "#search" do
    it "simple" do
      @c.respond_to?(:search).should == true      
    end
  end
  
  describe "workspace" do
    it "#get_workspace" do
      @w.name.should == 'abc'
      @w.route.should == { :workspaces => 'abc' }
      @w_default.name.should == 'default'
    end    
  end

  describe "layer" do
    it "#get_layer" do
      @c.get_layer('abc').name.should == 'abc'
    end    
  end
  
  describe "style" do
    it "#get_style" do
      @c.get_style('abc').name.should == 'abc'
    end    
  end


end 
