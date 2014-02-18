require 'spec_helper'

describe RGeoServer::RestApiClient do
  before(:each) do    
    @client = RGeoServer::Catalog.new
  end
  
  describe 'REST API sequences' do
    describe 'basic' do
      it 'main' do
        RGeoServer::RestApiClient::URI_SEQUENCES.each do |seq|
          seq.size.should > 0 and seq.size.should <= 4
          if seq.size == 1 and not seq[0] == :about
            @client.url_for(seq[0] => nil).should == seq[0].to_s
          elsif seq.size == 2
            @client.url_for(seq[0] => 'abc', seq[1] => nil).is_a?(String).should == true
          elsif seq.size == 3 and not seq[0] == :services
            @client.url_for(seq[0] => 'abc', seq[1] => 'xyz', seq[2] => nil).is_a?(String).should == true
          elsif seq.size == 4 and not seq[0] == :services
            false.should == true # NOTREACHED
          end
        end
      end
      
      it 'exceptions' do
        expect { 
          @client.url_for(:abc => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        
        RGeoServer::RestApiClient::URI_SEQUENCES.each do |seq|
          if seq.size > 1
            expect {
              @client.url_for(Hash[seq.map {|k| [k, nil]}])
            }.to raise_error RGeoServer::ArgumentError
          end
        end
      end
    end
    
    describe 'workspaces' do
      it 'main' do
        @client.url_for(:workspaces => nil).should == 'workspaces'
        @client.url_for(:workspaces => '').should == 'workspaces'
        @client.url_for('workspaces' => '').should == 'workspaces'
        @client.url_for(:workspaces => 'abc').should == 'workspaces/abc'
        @client.url_for(:workspaces => 'default').should == 'workspaces/default'
        @client.url_for(:workspaces => 'abc', :settings => nil).should == 'workspaces/abc/settings'
      end      
      it 'exceptions' do
        expect { 
          @client.url_for(:workspaces => 'default', :settings => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'default', :abc => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
      end
    end

    describe 'datastores' do
      it 'main' do
        what = {:workspaces => 'abc', :datastores => nil}
        base = 'workspaces/abc/datastores'
        @client.url_for(what).should == base + ''
        what[:datastores] = 'def'
        @client.url_for(what).should == base + '/def'
        @client.url_for(what.merge({:file => nil})).should == base + '/def/file'
        @client.url_for(what.merge({:external => nil})).should == base + '/def/external'
        @client.url_for(what.merge({:url => nil})).should == base + '/def/url'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:datastores => nil)
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:datastores => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:abc => 'abc', :datastores => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :datastores => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :datastores => 'def', :file => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :datastores => 'def', :external => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :datastores => 'def', :url => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :datastores => 'def', :xyz => nil)
        }.to raise_error RGeoServer::ArgumentError
      end
    end
    
    describe 'featuretypes' do
      it 'main' do
        what = {:workspaces => 'abc', :datastores => 'def', :featuretypes => nil}
        base = 'workspaces/abc/datastores/def/featuretypes'
        @client.url_for(what).should == base + ''
        what[:featuretypes] = 'xyz'
        @client.url_for(what).should == base + '/xyz'
      end
      
      it 'exceptions' do
        expect { 
          @client.url_for(:featuretypes => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :featuretypes => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:datastores => nil, :featuretypes => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :datastores => nil, :featuretypes => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :datastores => nil, :featuretypes => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :datastores => 'abc', :featuretypes => 'abc')
        }.to raise_error RGeoServer::ArgumentError
      end

    end
    
    describe 'styles' do
      it 'main' do
        @client.url_for(:styles => nil).should == 'styles'
        @client.url_for(:styles => 'abc').should == 'styles/abc'
        @client.url_for(:workspaces => 'abc', :styles => nil).should == 'workspaces/abc/styles'
        @client.url_for(:workspaces => 'abc', :styles => 'xyz').should == 'workspaces/abc/styles/xyz'
      end
    end
    
    describe 'layers' do
      it 'main' do
        @client.url_for(:layers => nil).should == 'layers'
        @client.url_for(:layers => 'abc').should == 'layers/abc'
        @client.url_for(:layers => 'abc', :styles => nil).should == 'layers/abc/styles'
        @client.url_for(:layers => 'abc', :styles => 'xyz').should == 'layers/abc/styles/xyz'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:workspaces => 'abc', :layers => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :layers => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :layers => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:abc => 'def', :layers => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:layers => 'abc', :abc => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
      end
      
    end
    
    describe 'layergroups' do
      it 'main' do
        base = 'layergroups'
        @client.url_for({:layergroups => nil}).should == base + ''
        @client.url_for({:layergroups => 'abc'}).should == base + '/abc'
      end

      it 'workspace' do      
        what = {:workspaces => 'abc', :layergroups => nil}
        base = 'workspaces/abc/layergroups'
        @client.url_for(what).should == base + ''
        what[:layergroups] = 'xyz'
        @client.url_for(what).should == base + '/xyz'
      end      
    end
    
    describe 'namespaces' do
      it 'main' do
        @client.url_for(:namespaces => nil).should == 'namespaces'
        @client.url_for(:namespaces => 'abc').should == 'namespaces/abc'
        @client.url_for(:namespaces => 'default').should == 'namespaces/default'
      end
      
    end

    describe 'coveragestores' do
      it 'main' do
        what = {:workspaces => 'abc', :coveragestores => nil}
        base = 'workspaces/abc/coveragestores'
        @client.url_for(what).should == base + ''
        what[:coveragestores] = 'xyz'
        @client.url_for(what).should == base + '/xyz'
        what[:file] = nil
        @client.url_for(what).should == base + '/xyz/file'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:coveragestores => nil)
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:abc => 'abc', :coveragestores => nil)
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :coveragestores => nil)
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :coveragestores => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :coveragestores => 'abc', :file => nil)
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :coveragestores => 'def', :file => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :coveragestores => 'def', :external => nil)
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :coveragestores => 'def', :url => nil)
        }.to raise_error RGeoServer::ArgumentError
      end
    end

    
    describe 'coverages' do
      it 'main' do
        what = {:workspaces => 'abc', :coveragestores => 'def', :coverages => nil}
        base = 'workspaces/abc/coveragestores/def/coverages'
        @client.url_for(what).should == base + ''
        what[:coverages] = 'xyz'
        @client.url_for(what).should == base + '/xyz'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:coverages => nil)
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :coverages => nil)
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :coverages => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :coveragestores => nil, :coverages => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => 'abc', :coveragestores => '', :coverages => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:workspaces => nil, :coveragestores => 'abc', :coverages => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
      end
      
    end
    
    describe 'about' do
      it 'main' do
        @client.url_for(:about => :version).should == 'about/version'
        @client.url_for(:about => 'version').should == 'about/version'
        @client.url_for(:about => :manifest).should == 'about/manifest'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:about => nil)
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:about => '')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:about => 'abc')
        }.to raise_error RGeoServer::ArgumentError
      end
      
    end

    describe 'fonts' do
      it 'main' do
        @client.url_for(:fonts => nil).should == 'fonts'
        @client.url_for(:fonts => '').should == 'fonts'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:fonts => 'abc')
        }.to raise_error RGeoServer::ArgumentError
      end
      
    end

    describe 'reload' do
      it 'main' do
        @client.url_for(:reload => nil).should == 'reload'
        @client.url_for(:reload => '').should == 'reload'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:reload => 'abc')
        }.to raise_error RGeoServer::ArgumentError
      end
      
    end

    describe 'reset' do
      it 'main' do
        @client.url_for(:reset => nil).should == 'reset'
        @client.url_for(:reset => '').should == 'reset'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:reset => 'abc')
        }.to raise_error RGeoServer::ArgumentError
      end
      
    end

    describe 'settings' do
      it 'main' do
        @client.url_for(:settings => nil).should == 'settings'
        @client.url_for(:settings => '').should == 'settings'
        @client.url_for(:settings => 'contact').should == 'settings/contact'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:settings => 'abc')
        }.to raise_error RGeoServer::ArgumentError
      end
      
    end
    
    describe 'services' do
      it 'main' do
        @client.url_for(:services => '', :wcs => '', :settings => '').should == 'services/wcs/settings'
        @client.url_for(:services => '', :wcs => '', :settings => nil).should == 'services/wcs/settings'
        @client.url_for(:services => '', :wfs => '', :settings => nil).should == 'services/wfs/settings'
        @client.url_for(:services => '', :wms => '', :settings => nil).should == 'services/wms/settings'
        @client.url_for(:services => '', :wcs => '', :workspaces => 'abc', :settings => nil).should == 'services/wcs/workspaces/abc/settings'
        @client.url_for(:services => '', :wfs => '', :workspaces => 'abc', :settings => nil).should == 'services/wfs/workspaces/abc/settings'
        @client.url_for(:services => '', :wms => '', :workspaces => 'abc', :settings => nil).should == 'services/wms/workspaces/abc/settings'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:services => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:services => '', :wcs => 'abc', :settings => nil)
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:services => '', :wcs => '', :settings => 'abc')
        }.to raise_error RGeoServer::ArgumentError
        expect { 
          @client.url_for(:services => '', :wcs => '', :workspaces => 'abc', :settings => 'xyz')
        }.to raise_error RGeoServer::ArgumentError
      end
      
    end

    describe 'templates' do
      it 'main' do
        @client.url_for(:templates => nil).should == 'templates'
        @client.url_for(:templates => 'abc.ftl').should == 'templates/abc.ftl'
      end

      it 'exceptions' do
        expect { 
          @client.url_for(:templates => 'abc')
        }.to raise_error RGeoServer::ArgumentError
      end
      
    end

  end
    
end 
