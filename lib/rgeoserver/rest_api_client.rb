require 'uri'
module RGeoServer
  module RestApiClient
    include RGeoServer::GeoServerUrlHelpers
    include ActiveSupport::Benchmarkable

    # Instantiates a rest client with passed configuration
    # @param [Hash] c configuration
    # @return [RestClient::Resource]
    # @yield [URI::InvalidURIError] if c[:url] is invalid
    def rest_client c
      ap({:rest_client => c}) if $DEBUG
      RestClient::Resource.new(URI(c[:url]).normalize.to_s,
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
        if c[:geowebcache_url].nil? or c[:geowebcache_url] == 'builtin'
          c[:url] = c[:url].gsub(%r{/rest$}, '/gwc/rest') # switch to built-in GeoServer GWC
        else
          c[:url] = c[:geowebcache_url]
        end
        @gwc_client = rest_client(c)
      end
      @gwc_client
    end

    def headers format = :xml
      {
        :accept => format.to_sym,
        :content_type => format.to_sym
      }
    end

    # Search a resource in the catalog
    # @param [OrderedHash] what
    # @param [Hash] options
    # @return [RestClient::Response] XML response
    def search what, options = {}
      h = options.delete(:headers) || headers(:xml)
      request = client[url_for(what, options)]
      request.options[:headers] = h
      begin
        ap({ :func => { :search => what }, :request => request }) if $DEBUG
        return request.get
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "search failed for #{what}: #{e}"
      end
    end

    # Do an action on an arbitrary URL path within the catalog
    # Default method is GET
    # @param [String] sub_url
    # @param [String] method
    # @param [String] data payload
    # @param [Hash] options for request
    # @return [RestClient::Response] XML response
    def do_url sub_url, method = :get, data = nil, options = {}
      sub_url.slice! client.url # remove prefixed URL
      fetcher = client[sub_url]
      fetcher.options.merge!(options)
      begin
        case method
        when :delete
          fetcher.delete  
        when :get
          fetcher.get
        when :put
          fetcher.put data
        when :post
          fetcher.post data
        else
          raise GeoServerArgumentError, "Invalid method type for do_url: #{method}"
        end
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "do_url failed for #{sub_url}: #{e}"
      end
    end

    # Add resource to the catalog
    # @param [String] what
    # @param [String] message
    # @param [Symbol] method
    # @param [Hash] options
    # @return [RestClient::Response] XML response
    def add what, message, method = :put, options = {}
      h = options.delete(:headers) || headers(:xml)
      request = client[url_for(what, options)]
      request.options[:headers] = h
      $logger.debug "Adding: #{message}"
      begin
        ap({:add_request => request, :add_message => Nokogiri::XML(message)}) if $DEBUG
        case method
        when :put
          request.put message
        when :post
          request.post message
        else
          raise GeoServerArgumentError, "Invalid method type for add: #{method}"
        end
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "add failed for #{what}: #{e}"
      end
    end

    # Modify resource in the catalog
    # @param [String] what
    # @param [String] message
    # @param [Symbol] method
    # @param [Hash] options
    # @return [RestClient::Response] XML response
    def modify what, message, method = :put, options = {}
      h = options.delete(:headers) || headers(:xml)
      request = client[url_for(what, options)]
      request.options[:headers] = h
      $logger.debug "Modifying: #{message}"
      begin
        ap({:modify_request => request, :modify_message => Nokogiri::XML(message)}) if $DEBUG
        case method
        when :put
          request.put message
        when :post
          request.post message
        else
          raise GeoServerArgumentError, "Invalid method type for modify: #{method}"
        end
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "modify failed for #{what}: #{e}"
      end

    end

    # Purge resource from the catalog. Options can include recurse=true or false
    # @param [OrderedHash] what
    # @param [Hash] options
    # @return [RestClient::Response] XML response
    def purge what, options
      request = client[url_for(what, options)]
      $logger.debug "Purging: #{what}"
      begin
        ap({:purge_request => request}) if $DEBUG
        return request.delete
      rescue RestClient::InternalServerError => e
        $logger.error e.response
        $logger.flush if $logger.respond_to? :flush
        raise GeoServerInvalidRequest, "purge failed for #{what}: #{e}"
      end
    end

  end
end
