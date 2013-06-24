require 'logger'
$logger = Logger.new(STDERR)
$logger.level = Logger::INFO

module RGeoServer
  module RestApiClient

    include RGeoServer::GeoServerUrlHelpers
    include ActiveSupport::Benchmarkable

    # Instantiates a rest client with passed configuration
    # @param [Hash] c configuration 
    # return [RestClient::Resource]
    def rest_client c
      ap({:rest_client => c}) if $DEBUG
      raise ArgumentError, "#rest_client requires :url" if c[:url].nil?
      RestClient::Resource.new(c[:url], 
          :user => c[:user], 
          :password => c[:password], 
          :headers => c[:headers], 
          :timeout => (c[:timeout] || 300).to_i,
          :open_timeout => (c[:open_timeout] || 60).to_i)
    end

    # @return [RestClient] cached or new client
    def client config = {}
      @client ||= rest_client(config.merge(self.config[:restclient]).merge(self.config))
    end

    # @return [RestClient] cached or new client
    def gwc_client config = {}
      unless @gwc_client.is_a? RestClient::Resource
        c = config.merge(self.config[:restclient]).merge(self.config)
        if c[:geowebcache_url] and c[:geowebcache_url] != 'builtin'
          c[:url] = c[:geowebcache_url]
        else
          c[:url] = c[:url].gsub(%r{/rest$}, '/gwc/rest') # switch to built-in GeoServer GWC
        end
        @gwc_client = rest_client(c)
      end
      @gwc_client
    end

    def headers format
      sym = :xml || format.to_sym
      {:accept => sym, :content_type=> sym}
    end

    # Search a resource in the catalog
    # @param [OrderedHash] what
    # @param [Hash] options
    def search what, options = {}
      h = options.delete(:headers) || headers(:xml)
      resources = client[url_for(what, options)]
      resources.options[:headers] = h
      begin
        ap({ :func => { :search => what }, :request => resources }) if $DEBUG
        return resources.get
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "Error listing #{what.inspect}. See $logger for details"
      end
    end

    # Do an action on an arbitrary URL path within the catalog 
    # Default method is GET 
    # @param [String] sub_url 
    # @param [String] method 
    # @param [String] data payload 
    # @param [Hash] options for request 
    def do_url sub_url, method = :get, data = nil, options = {}, client = client
      sub_url.slice! client.url
      fetcher = client[sub_url] 
      fetcher.options.merge(options)
      begin
        return fetcher.get if method == :get  
        fetcher.send method, data 
      rescue RestClient::InternalServerError => e 
        $logger.error e.response 
        $logger.flush if $logger.respond_to? :flush 
        raise GeoServerInvalidRequest, "Error fetching URL: #{sub_url}. See $logger for details" 
      end 
    end 

    # Add resource to the catalog
    # @param [String] what
    # @param [String] message
    # @param [Symbol] method
    # @param [Hash] options
    def add what, message, method, options = {}
      h = options.delete(:headers) || headers(:xml)
      request = client[url_for(what, options)]
      request.options[:headers] = h
      $logger.debug "Adding: \n #{message}"
      begin 
        ap({:add_request => request, :add_message => Nokogiri::XML(message)}) if $DEBUG
        return request.send method, message
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "Error adding #{what.inspect}. See logger for details"
      end
      
    end

    # Modify resource in the catalog
    # @param [String] what
    # @param [String] message
    # @param [Symbol] method
    # @param [Hash] options
    def modify what, message, method, options = {}
      h = options.delete(:headers) || headers(:xml)
      request = client[url_for(what, options)]
      request.options[:headers] = h
      $logger.debug "Modifying: \n #{message}"
      begin
        ap({:modify_request => request, :modify_message => Nokogiri::XML(message)}) if $DEBUG
        return request.send method, message
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "Error modifying #{what.inspect}. See $logger for details"
      end
      
    end

    # Purge resource from the catalog. Options can include recurse=true or false
    # @param [OrderedHash] what
    # @param [Hash] options
    def purge what, options
      request = client[url_for(what, options)]
      $logger.debug "Purge: \n #{request}"
      begin
        ap({:purge_request => request}) if $DEBUG
        return request.delete
      rescue RestClient::InternalServerError => e 
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "Error deleting #{what.inspect}. See $logger for details"
      end
    end

  end
end
