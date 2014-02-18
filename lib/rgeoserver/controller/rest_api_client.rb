require 'restclient'

require 'logger'
$logger = Logger.new(STDERR) # XXX: Use config[:restclient][:logfile]
$logger.level = Logger::INFO

#
module RGeoServer
  module RestApiClient

    include RGeoServer::GeoServerUrlHelpers
    include ActiveSupport::Benchmarkable

    public
    # @param [Hash] config
    # @return [RestClient] cached or new client
    def client config = {}
      @client ||= rest_client(config.merge(self.config[:restclient]).merge(self.config))
    end

    # @param [Hash] config
    # @return [RestClient] cached or new client
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

    def headers
      { 
        :accept => 'text/xml',
        :content_type => 'text/xml'
      }
    end

    # Search a resource in the catalog
    # @param [OrderedHash] what
    # @param [Hash] options
    def search what, options = {}
      request = client[url_for(what, options)]
      request.options[:headers] = headers
      begin
        log_debug "#{self.class}#search: #{what}"
        request.get
      rescue RestClient::ExceptionWithResponse => e
        log_error e.response
        raise RGeoServer::InvalidRequest, "#{self.class}#search: #{what}: #{e.inspect}"
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
      request = client[sub_url] 
      request.options.merge(options)
      begin
        log_debug "#{self.class}#do_url: #{method} #{data}"
        if method == :get
          request.get
        else 
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
    # @param [Symbol] method
    # @param [Hash] options
    def add what, data, method, options = {}
      request = client[url_for(what, options)]
      request.options[:headers] = headers
      begin 
        log_debug "#{self.class}#add #{what}: #{method} #{data}"
        request.send method, data
      rescue RestClient::ExceptionWithResponse => e
        log_error e.response
        raise RGeoServer::InvalidRequest, "#{self.class}#add #{what}: #{e.inspect}"
      end
      
    end

    # Modify resource in the catalog
    # @param [String] what
    # @param [String] data
    # @param [Symbol] method
    # @param [Hash] options
    def modify what, data, method, options = {}
      request = client[url_for(what, options)]
      request.options[:headers] = headers
      begin
        log_debug "#{self.class}#modify #{what}: #{method} #{data}"
        request.send method, message
      rescue RestClient::ExceptionWithResponse => e
        log_error e.response
        raise RGeoServer::InvalidRequest, "#{self.class}#modify #{what}: #{e.inspect}"
      end
      
    end

    # Purge resource from the catalog. Options can include recurse=true or false
    # @param [OrderedHash] what
    # @param [Hash] options
    def purge what, method = :delete, options = {}
      request = client[url_for(what, options)]
      begin
        log_debug "#{self.class}#delete #{what}: #{method}"
        request.delete
      rescue RestClient::ExceptionWithResponse => e 
        log_error e.response
        raise RGeoServer::InvalidRequest, "#{self.class}#delete #{what}: #{e.inspect}"
      end
    end
    
    private
    # Instantiates a rest client with passed configuration
    # @param [Hash] config configuration 
    # return [RestClient::Resource]
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
