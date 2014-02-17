require 'spec_helper'

describe RGeoServer::RestApiClient do
  before(:each) do    
    @client = RGeoServer::Catalog.new
  end
  
  describe 'REST API sequences' do
    describe 'basic' do
      it 'main' do
        RGeoServer::RestApiClient::URI_SEQUENCES.each do |seq|
          @client.url_for(Hash[seq.map {|k| [k, 'abc']}]).is_a?(String).should == true
        end
        @client.url_for('about' => nil).should == 'about'
      end
      
      it 'exceptions' do
        expect { 
          @client.url_for(:abc => 'abc')
        }.to raise_error RGeoServer::GeoServerArgumentError
        expect {
          @client.url_for(:workspaces => nil, :datastores => 'abc')
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
        @client.url_for(:workspaces => nil).should == 'workspaces'
        @client.url_for(:workspaces => 'druid').should == 'workspaces/druid'
        @client.url_for(:workspaces => 'default').should == 'workspaces/default'
      end      
    end

    describe 'datastores' do
      it 'main' do
        what = {:workspaces => 'druid', :datastores => nil}
        base = 'workspaces/druid/datastores'
        @client.url_for(what).should == base + ''
        what[:datastores] = 'abc'
        @client.url_for(what).should == base + '/abc'
        @client.url_for(what.merge({:file => nil})).should == base + '/abc/file'
        @client.url_for(what.merge({:external => nil})).should == base + '/abc/external'
        @client.url_for(what.merge({:url => nil})).should == base + '/abc/url'
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
        @client.url_for(what).should == base + ''
        what[:featuretypes] = 'xyz'
        @client.url_for(what).should == base + '/xyz'
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
        @client.url_for(:layers => nil).should == 'layers'
        @client.url_for(:layers => 'abc').should == 'layers/abc'
        @client.url_for(:layers => 'abc', :styles => nil).should == 'layers/abc/styles'
      end

      it 'exceptions' do
        # expect { 
        #           @client.url_for(:layers => 'abc', :styles => 'xyz')
        #         }.to raise_error RGeoServer::GeoServerArgumentError
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
        @client.url_for({:layergroups => nil}).should == base + ''
        @client.url_for({:layergroups => 'abc'}).should == base + '/abc'
      end

      it 'workspace' do      
        what = {:workspaces => 'druid', :layergroups => nil}
        base = 'workspaces/druid/layergroups'
        @client.url_for(what).should == base + ''
        what[:layergroups] = 'abc'
        @client.url_for(what).should == base + '/abc'
      end      
    end
    
    describe 'namespaces' do
      it 'main' do
        @client.url_for(:namespaces => nil).should == 'namespaces'
        @client.url_for(:namespaces => 'abc').should == 'namespaces/abc'
        @client.url_for(:namespaces => 'default').should == 'namespaces/default'
      end
      
    end
    
    describe 'coverages' do
      it 'main' do
        what = {:workspaces => 'druid', :coveragestores => 'abc', :coverages => nil}
        base = 'workspaces/druid/coveragestores/abc/coverages'
        @client.url_for(what).should == base + ''
        what[:coverages] = 'xyz'
        @client.url_for(what).should == base + '/xyz'
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
        @client.url_for(:about => :version).should == 'about/version'
        @client.url_for(:about => :manifest).should == 'about/manifest'
      end

      it 'exceptions' do
        # expect { 
        #   @client.url_for(:about => nil)
        # }.to raise_error RGeoServer::GeoServerArgumentError
        # expect { 
        #   @client.url_for(:about => 'abc')
        # }.to raise_error RGeoServer::GeoServerArgumentError
      end
      
    end
  end
    
end 
