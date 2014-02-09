module RGeoServer
  # This class represents the main class of the data model, and provides all REST APIs to GeoServer.
  # @see http://geoserver.org/display/GEOS/Catalog+Design
  # @see http://docs.geoserver.org/stable/en/user/rest/api/

  class Catalog
    include RGeoServer::RestApiClient

    attr_reader :config

    # @param [OrderedHash] options if nil, uses RGeoServer::Config[:geoserver] loaded from $RGEOSERVER_CONFIG or config/defaults.yml
    # options :url
    # options :user
    # options :password
    def initialize options = nil
      @config = options || RGeoServer::Config[:geoserver]
      unless config.include?(:url)
        raise GeoServerArgumentError, "Catalog: Requires :url option: #{config}"
      end
      RestClient.log = config[:logfile] || nil
    end

    def to_s
      "Catalog: #{config[:url]}"
    end

    #== Resources

    # Shortcut to ResourceInfo.list to this catalog. See ResourceInfo#list
    # @param [RGeoServer::ResourceInfo.class] klass
    # @param [Array<String>] names
    # @param [Hash] options
    # @param [bool] check_remote if already exists in catalog and cache it
    # @yield [RGeoServer::ResourceInfo]
    def list klass, names, options = {}, check_remote = false, &block
      unless names.is_a? Array and not names.empty?
        raise ArgumentError, "Missing names #{names}" 
      end
      ResourceInfo.list klass, self, names, options, check_remote, &block
    end

    #= Workspaces

    # List of available workspaces
    # @return [Array<RGeoServer::Workspace>]
    def get_workspaces
      doc = Nokogiri::XML(search :workspaces => nil)
      workspaces = doc.xpath("#{Workspace.root_xpath}/name/text()").collect {|w| w.to_s }
      list Workspace.class, workspaces
    end

    # @param  [String] ws workspace name
    # @return [RGeoServer::Workspace]
    def get_workspace ws
      doc = Nokogiri::XML(search :workspaces => ws)
      Workspace.new self, :name => parse_name(doc, Workspace)
    end
    

    # @return [RGeoServer::Workspace] get_workspace('default')
    def get_default_workspace
      get_workspace 'default'
    end

    # Assign default workspace
    # @param [String] workspace name
    def set_default_workspace workspace
      raise TypeError, "Workspace name must be a string" unless workspace.instance_of? String
      dws = Workspace.new self, :name => 'default'
      dws.name = workspace # This creates a new workspace if name is new
      dws.save
      dws
    end

    # @deprecated see RGeoServer::Workspace
    # @param [String] store
    # @param [String] workspace
    def reassign_workspace store, workspace
      raise NotImplementedError
    end

    #= Layers

    # List of available layers
    # @param [Hash] options
    # @return [Array<RGeoServer::Layer>]
    def each_layer options = {}
      doc = Nokogiri::XML(self.search :layers => nil)
      ap({:each_layer_doc => doc, :xpath => Layer.root_xpath}) if $DEBUG
      doc.xpath(Layer.root_xpath + '/name/text()').each { |l|
        ap({:layer => l.to_s.strip}) if $DEBUG
        yield get_layer l.to_s.strip unless l.nil?
      }
    end

    # @param [String] layername
    # @return [RGeoServer::Layer]
    def get_layer layername
      raise ArgumentError, "#get_layer requires String #{layername}" unless layername.is_a? String
      ap({:layers => layername}) if $DEBUG
      doc = Nokogiri::XML(search :layers => layername)
      Layer.new self, :name => layername
    end

    #= LayerGroups

    # List of available layer groups
    # @param [Hash] options
    # @return [Array<RGeoServer::LayerGroup>]
    def get_layergroups options = {}
      response = unless options[:workspace]
                   self.search :layergroups => nil
                 else
                   self.search :workspaces => options[:workspace], :layergroups => nil
                 end
      doc = Nokogiri::XML(response)
      layer_groups = doc.xpath(LayerGroup.root_xpath).collect{|l| l.text.to_s }.map(&:strip)
      list LayerGroup, layer_groups, :workspace => options[:workspace]
    end

    # @param [String] layergroup name
    # @return [RGeoServer::LayerGroup]
    def get_layergroup layergroup
      doc = Nokogiri::XML(search :layergroups => layergroup)
      LayerGroup.new self, :name => parse_name(doc, LayerGroup)
    end

    #= Styles (SLD Style Layer Descriptor)

    # List of available styles
    # @return [Array<RGeoServer::Style>]
    def get_styles
      doc = Nokogiri::XML(search :styles => nil)
      styles = doc.xpath("#{Style.root_xpath}/name/text()").collect {|s| s.to_s }
      list Style, styles
    end

    # @param [String] style name
    # @return [RGeoServer::Style]
    def get_style style
      doc = Nokogiri::XML(search :styles => style)
      Style.new self, :name => parse_name(doc, Style)
    end


    #= Namespaces

    # List of available namespaces
    # @return [Array<RGeoServer::Namespace>]
    def get_namespaces
      raise NotImplementedError
    end

    # @return [RGeoServer::Namespace]
    def get_default_namespace
      doc = Nokogiri::XML(search :namespaces => 'default')
      Namespace.new self, :name => parse_name(doc, Namespace, 'prefix'), 
                          :uri => parse_name(doc, Namespace, 'uri')
    end

    def set_default_namespace id, prefix, uri
      raise NotImplementedError
    end

    #= Data Stores (Vector datasets)

    # List of vector based spatial data
    # @param [String] workspace
    # @return [Array<RGeoServer::DataStore>]
    def get_data_stores workspace = nil
      ws = workspace.nil?? get_workspaces : [get_workspace(workspace)]
      ws.map { |w| w.data_stores }.flatten
    end

    # @param [String] workspace
    # @param [String] datastore
    # @return [RGeoServer::DataStore]
    def get_data_store workspace, datastore
      doc = Nokogiri::XML(search :workspaces => workspace, :datastores => datastore)
      DataStore.new self, :workspace => workspace, 
                          :name => parse_name(doc, DataStore)
    end

    # List of feature types
    # @param [String] workspace
    # @param [String] datastore
    # @return [Array<RGeoServer::FeatureType>]
    def get_feature_types workspace, datastore, &block
      raise NotImplementedError
    end

    # @param [String] workspace
    # @param [String] datastore
    # @param [String] featuretype_id
    # @return [RGeoServer::FeatureType]
    def get_feature_type workspace, datastore, featuretype_id
      raise NotImplementedError
    end

    #= Coverages (Raster datasets)

    # List of coverage stores
    # @param [String] workspace
    # @return [Array<RGeoServer::CoverageStore>]
    def get_coverage_stores workspace = nil
      ws = workspace.nil?? get_workspaces : [get_workspace(workspace)]
      ws.map { |w| w.coverage_stores }.flatten
    end

    # @param [String] workspace
    # @param [String] coveragestore
    # @return [RGeoServer::CoverageStore]
    def get_coverage_store workspace, coveragestore
      cs = CoverageStore.new self, :workspace => workspace, :name => coveragestore
      return cs.new?? nil : cs
    end

    def get_coverage workspace, coverage_store, coverage
      c = Coverage.new self, 
                       :workspace => workspace, 
                       :coverage_store => coverage_store, 
                       :name => coverage
      return c.new?? nil : c
    end

    #= WMS Stores (Web Map Services)

    # List of WMS stores.
    # @param [String] workspace
    # @return [Array<RGeoServer::WmsStore>]
    def get_wms_stores workspace = nil
      ws = workspace.nil?? get_workspaces : [get_workspace(workspace)]
      ws.map { |w| w.wms_stores }.flatten
    end

    # @param [String] workspace
    # @param [String] wmsstore
    # @return [RGeoServer::WmsStore]
    def get_wms_store workspace, wmsstore
      doc = Nokogiri::XML(search :workspaces => workspace, :name => wmsstore)
      WmsStore.new self, workspace, parse_name(doc, WmsStore)
    end

    #= Configuration reloading
    # Reloads the catalog and configuration from disk. This operation is used to reload GeoServer in cases where an external tool has modified the on disk configuration. This operation will also force GeoServer to drop any internal caches and reconnect to all data stores.
    def reload
      do_url 'reload', :put
    end

    #= Resource reset
    # Resets all store/raster/schema caches and starts fresh. This operation is used to force GeoServer to drop all caches and stores and reconnect fresh to each of them first time they are needed by a request. This is useful in case the stores themselves cache some information about the data structures they manage that changed in the meantime.
    def reset
      do_url 'reset', :put
    end

    private
    def parse_name doc, klass, k = 'name'
      name = doc.at_xpath("#{klass.member_xpath}/#{k}/text()")
      name = name.to_s unless name.nil?
      name
    end

  end

end
