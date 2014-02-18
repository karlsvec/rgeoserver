require 'restclient'

require 'logger'
$logger = Logger.new(STDERR) # XXX: Use config[:restclient][:logfile]
$logger.level = Logger::INFO

module RGeoServer
  # Uses 'restclient' to build CRUD API
  module RestApiClient

    include RGeoServer::GeoServerUrlHelpers
    include ActiveSupport::Benchmarkable

    public
    # Instantiates a REST client with passed configuration
    # @param [Hash] config
    # @option config [String] :url
    # @option config [String] :user
    # @option config [String] :password
    # @option config [Hash] :headers
    # @option config [Integer] :timeout
    # @option config [Integer] :open_timeout
    # @return [RestClient::Resource] cached or new client
    # @raise [RGeoServer::ArgumentError]
    def client config = {}
      @client ||= rest_client(config.merge(self.config[:restclient]).merge(self.config))
    end

    # Instantiates a GeoWebCache client with passed configuration
    # @param [Hash] config
    # @option options [String] :url
    # @option options [String] :geowebcache_url
    # @return [RestClient::Resource] cached or new client
    def gwc_client config = {}
      unless @gwc_client.is_a? RestClient::Resource
        c = config.merge(self.config[:restclient]).merge(self.config)
        if c[:geowebcache_url].nil? or c[:geowebcache_url] == 'builtin'
          c[:url] = c[:url].gsub(%r{/rest$}, '/gwc/rest') # switch to built-in GeoServer GWC
        else
          c[:url] = c[:geowebcache_url]
        end
        @gwc_client = rest_client(c)
      end
      @gwc_client
    end

    # Search for a resource in the catalog
    # @param [OrderedHash] what
    # @param [Hash] options for `url_for`
    # @option options [String] :headers
    # @return [String] response
    def search what, options = {}
      request = client[url_for(what, options)]
      request.options[:headers] = headers
      begin
        log_debug "#{self.class}#search: GET #{what}"
        request.get
      rescue RestClient::ExceptionWithResponse => e
        log_error e.response
        raise RGeoServer::InvalidRequest, "#{self.class}#search: #{what}: #{e.inspect}"
      end
    end

    # Do an action on an arbitrary URL path within the catalog 
    # @param [String] sub_url 
    # @param [String] data payload 
    # @param [String] method 
    # @param [Hash] options for request 
    # @param [RestClient::Resource] client
    # @return [String] response 
    def do_url sub_url, data = nil, method = :get, options = {}, client = client
      sub_url.slice! client.url # if full path equivalence
      request = client[sub_url] 
      request.options.merge(options)
      begin
        if method == :get
          log_debug "#{self.class}#do_url: GET #{sub_url}"
          request.get
        else 
          log_debug "#{self.class}#do_url: #{method} #{sub_url}: #{data}"
          request.send method, data 
        end
      rescue RestClient::ExceptionWithResponse => e 
        log_error e.response
        raise RGeoServer::InvalidRequest, "#{self.class}#do_url #{sub_url}: #{e.inspect}"
      end 
    end 

    # Add resource to the catalog
    # @param [String] what
    # @param [String] data
    # @param [Hash] options for `url_for`
    # @return [String] response
    def add what, data, options = {}
      request = client[url_for(what, options)]
      request.options[:headers] = headers
      begin 
        log_debug "#{self.class}#add: POST #{what}: #{data}"
        request.post data
      rescue RestClient::ExceptionWithResponse => e
        log_error e.response
        raise RGeoServer::InvalidRequest, "#{self.class}#add #{what}: #{e.inspect}"
      end
      
    end

    # Modify resource in the catalog
    # @param [String] what
    # @param [String] data
    # @param [Hash] options for `url_for`
    # @return [String] response
    def modify what, data, options = {}
      request = client[url_for(what, options)]
      request.options[:headers] = headers
      begin
        log_debug "#{self.class}#modify PUT #{what}: #{data}"
        request.put data
      rescue RestClient::ExceptionWithResponse => e
        log_error e.response
        raise RGeoServer::InvalidRequest, "#{self.class}#modify #{what}: #{e.inspect}"
      end
      
    end

    # Purge resource from the catalog.
    # @param [OrderedHash] what
    # @param [Hash] options for `url_for`
    # @return [String] response
    def purge what, options = {}
      request = client[url_for(what, options)]
      begin
        log_debug "#{self.class}#delete: DELETE #{what}"
        request.delete
      rescue RestClient::ExceptionWithResponse => e 
        log_error e.response
        raise RGeoServer::InvalidRequest, "#{self.class}#delete #{what}: #{e.inspect}"
      end
    end
    
    # @return [Hash]
    def headers
      { 
        :accept => 'application/json',
        :content_type => 'application/json'
      }
    end
    
    private
    def rest_client config
      raise RGeoServer::ArgumentError, "#{self.class}#rest_client requires :url" if config[:url].nil?
      RestClient::Resource.new(
        config[:url], 
        :user => config[:user] || nil, 
        :password => config[:password] || nil, 
        :headers => config[:headers] || headers, 
        :timeout => (config[:timeout] || 300).to_i,
        :open_timeout => (config[:open_timeout] || 60).to_i
      )
    end

    def log_debug s
      $logger.debug s.to_s
      $logger.flush if $logger.respond_to? :flush
    end

    def log_error s
      $logger.error s.to_s
      $logger.flush if $logger.respond_to? :flush
    end
  end
end
