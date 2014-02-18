module RGeoServer
  # metadata utilities
  class Metadata
    
    # Example: 
    #     ft.keywords = [
    #       { :keyword => "United States", 
    #         :language => "en", 
    #         :vocabulary=>"ISOTC211/19115:place" }
    #      ]
    #
    # yields:
    #
    #     United States\@language=en\;\@vocabulary=ISOTC211/19115:place\;
    #
    # @see http://geoserver.org/display/GEOS/GSIP+64+-+Keyword+Vocabularies+and+Languages
    def self.to_keyword k
      if k.is_a? Hash
        k = k.inject({}){|h,(k,v)| h[k.to_sym] = v; h}
        k = "#{k[:keyword]}" +
            (("\\@language=#{k[:language]}\\;" if k[:language])||"") +
            (("\\@vocabulary=#{k[:vocabulary]}\\;" if k[:vocabulary])||"")
      end
      k.to_s
    end
  end
end