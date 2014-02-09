require 'spec_helper'

describe RGeoServer::RestApiClient do
  before(:each) do    
    @client = RGeoServer::Catalog.new
  end
  
  describe 'REST API sequences' do
    describe 'basic' do
      it 'main' do
        RGeoServer::RestApiClient::URI_SEQUENCES.each do |seq|
          if not [[:about], [:layers, :styles]].include? seq
            @client.url_for(Hash[seq.map {|k| [k, 'abc']}]).is_a?(String).should == true
          end
        end
      end
      
      it 'exceptions' do
        expect { 
          @client.url_for(:abc => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect {
          @client.url_for({:workspaces => nil}, {:format => 'abc'})
        }.to raise_error RGeoServer::GeoServerArgumentError
        
        RGeoServer::RestApiClient::URI_SEQUENCES.each do |seq|
          if seq.size > 1
            expect {
              @client.url_for(Hash[seq.map {|k| [k, nil]}])
            }.to raise_error RGeoServer::GeoServerArgumentError
          end
        end
      end
    end
    
    describe 'workspaces' do
      it 'main' do
        @client.url_for(:workspaces => nil).should == 'workspaces.xml'
        @client.url_for(:workspaces => 'druid').should == 'workspaces/druid.xml'
        @client.url_for(:workspaces => 'default').should == 'workspaces/default.xml'
      end
      
      it 'formats' do
        @client.url_for(:workspaces => nil).should == 'workspaces.xml'
        @client.url_for({:workspaces => nil}, {:format => :xml}).should == 'workspaces.xml'
        @client.url_for({:workspaces => nil}, {:format => :html}).should == 'workspaces.html'
        @client.url_for({:workspaces => nil}, {:format => :json}).should == 'workspaces.json'
      end
    end

    describe 'datastores' do
      it 'main' do
        what = {:workspaces => 'druid', :datastores => nil}
        base = 'workspaces/druid/datastores'
        @client.url_for(what).should == base + '.xml'
        what[:datastores] = 'abc'
        @client.url_for(what).should == base + '/abc.xml'
        @client.url_for(what.merge({:file => nil})).should == base + '/abc/file.xml'
        @client.url_for(what.merge({:external => nil})).should == base + '/abc/external.xml'
        @client.url_for(what.merge({:url => nil})).should == base + '/abc/url.xml'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:datastores => nil)
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:datastores => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :datastores => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :datastores => 'abc', :file => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :datastores => 'abc', :abc => nil)
        }.to raise_error RGeoServer::GeoServerArgumentError
      end
    end
    
    describe 'featuretypes' do
      it 'main' do
        what = {:workspaces => 'druid', :datastores => 'abc', :featuretypes => nil}
        base = 'workspaces/druid/datastores/abc/featuretypes'
        @client.url_for(what).should == base + '.xml'
        what[:featuretypes] = 'xyz'
        @client.url_for(what).should == base + '/xyz.xml'
      end
      
      it 'exceptions' do
        expect { 
          @client.url_for(:featuretypes => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :featuretypes => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:datastores => nil, :featuretypes => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :datastores => nil, :featuretypes => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :datastores => nil, :featuretypes => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :datastores => 'abc', :featuretypes => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
      end

    end
    
    describe 'layers' do
      it 'main' do
        @client.url_for(:layers => nil).should == 'layers.xml'
        @client.url_for(:layers => 'abc').should == 'layers/abc.xml'
        @client.url_for(:layers => 'abc', :styles => nil).should == 'layers/abc/styles.xml'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:layers => 'abc', :styles => 'xyz')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => 'druid', :layers => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :layers => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => 'druid', :layers => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
      end
      
    end
    
    describe 'layergroups' do
      it 'main' do
        base = 'layergroups'
        @client.url_for({:layergroups => nil}).should == base + '.xml'
        @client.url_for({:layergroups => 'abc'}).should == base + '/abc.xml'
      end

      it 'workspace' do      
        what = {:workspaces => 'druid', :layergroups => nil}
        base = 'workspaces/druid/layergroups'
        @client.url_for(what).should == base + '.xml'
        what[:layergroups] = 'abc'
        @client.url_for(what).should == base + '/abc.xml'
      end      
    end
    
    describe 'namespaces' do
      it 'main' do
        @client.url_for(:namespaces => nil).should == 'namespaces.xml'
        @client.url_for(:namespaces => 'abc').should == 'namespaces/abc.xml'
        @client.url_for(:namespaces => 'default').should == 'namespaces/default.xml'
      end
      
    end
    
    describe 'coverages' do
      it 'main' do
        what = {:workspaces => 'druid', :coveragestores => 'abc', :coverages => nil}
        base = 'workspaces/druid/coveragestores/abc/coverages'
        @client.url_for(what).should == base + '.xml'
        what[:coverages] = 'xyz'
        @client.url_for(what).should == base + '/xyz.xml'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:coverages => nil)
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => 'druid', :coverages => nil)
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => 'druid', :coverages => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:workspaces => 'druid', :coveragestores => nil, :coverages => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
      end
      
    end
    
    describe 'about' do
      it 'main' do
        @client.url_for(:about => :version).should == 'about/version.xml'
        @client.url_for(:about => :manifest).should == 'about/manifest.xml'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:about => nil)
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect { 
          @client.url_for(:about => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
      end
      
    end
  end
    
end 
