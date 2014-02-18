require 'rgeo'

module RGeoServer
  # implements a min/max x/y bounding box rectangle
  class BoundingBox
    attr_reader :minx, :miny, :maxx, :maxy

    @@epsilon = 0.0001

    def self.epsilon
      @@epsilon
    end

    def self.epsilon= value
      @@epsilon = value
    end
    
    # @param [Array] a in [minx, miny, maxx, maxy]
    def self.from_a a
      self.class.new Hash.new('minx' => a[0].to_f,
                              'miny' => a[1].to_f,
                              'maxx' => a[2].to_f,
                              'maxy' => a[3].to_f)
        
    end

    def initialize options = {}
      reset
      if ['minx', 'miny', 'maxx', 'maxy'].all? {|k| options.include?(k)}
        add options['minx'].to_f, options['miny'].to_f # SW
        add options['maxx'].to_f, options['maxx'].to_f # NE
      end
    end

    def reset
      @minx = @miny = @maxx = @maxy = 0.0
      @empty = true
    end

    def << point
      add point[0], point[1]
    end
    
    def add x, y
      if @empty
        @minx = @maxx = x
        @miny = @maxy = y
      end

      @minx = [minx, x].min
      @miny = [miny, y].min
      @maxx = [maxx, x].max
      @maxy = [maxy, y].max

      @empty = false
    end

    # @return [Array]
    def min
      [minx, miny]
    end

    # @return [Array]
    def max
      [maxx, maxy]
    end

    def expand rate = @@epsilon
      _minx, _miny = [minx - rate, miny - rate]
      _maxx, _maxy = [maxx + rate, maxy + rate]

      reset

      add _minx, _miny
      add _maxx, _maxy
    end

    def constrict rate = @@epsilon
      expand(-rate)
    end
    
    def width
      maxx - minx
    end
    
    def height
      maxy - miny
    end
    
    def area
      width * height
    end
    
    # @return [Boolean] true if bounding box has non-zero area
    def valid?
      area > 0
    end

    # @return [RGeo::Envelope]
    def to_geometry
      factory = RGeo::Cartesian::Factory.new

      point_min, point_max = unless [minx, miny] == [maxx, maxy]
        [factory.point(minx, miny), factory.point(maxx, maxy)]
      else
        [factory.point(minx - @@epsilon, miny - @@epsilon),
         factory.point(maxx + @@epsilon, maxy + @@epsilon)]
      end

      line_string = factory.line_string [point_min, point_max]
      line_string.envelope
    end
    
    # @return [Hash]
    def to_h
      {
        :minx => minx,
        :miny => miny,
        :maxx => maxx,
        :maxy => maxy
      }
    end

    # @return [Array]
    def to_a
      [minx, miny, maxx, maxy]
    end

    # @return [String]
    def to_s
      to_a.join(', ')
    end

    def inspect
      "#<#{self.class} #{to_s}>"
    end
  end
end
