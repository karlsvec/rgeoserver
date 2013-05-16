
module RGeoServer
  module GeoServerUrlHelpers
    # See http://docs.geoserver.org/latest/en/user/rest/api/
    # @return [String] baseURL for REST API, e.g.,:
    # - layers/_name_.xml
    # - styles/_name_.xml
    # - workspaces/_name_.xml
    # - namespaces/_name_.xml
    # - workspaces/_name_/datastores/_name_.xml
    # - workspaces/_name_/datastores/_name_/featuretype/_name_.xml
    def url_for base, options = nil
      base = { base => nil } unless base.is_a? Hash
      format = options.delete(:format) || 'xml'
      new_base = base.map{ |key,value|  value.nil?? key.to_s : [key.to_s, CGI::escape(value.to_s)].join("/")  }.join("/") 
      new_base = new_base.gsub(/\/$/,'')
      new_base += ".#{format}"
      new_base += (("?#{options.map { |key, value|  "#{CGI::escape(key.to_s)}=#{CGI::escape(value.to_s)}"}.join("&")  }" if options and not options.empty?) || '')
      # ap({:base => base, :new_base => new_base }) if $DEBUG
      new_base
    end

  end
end
