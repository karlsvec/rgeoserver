require 'spec_helper'

describe RGeoServer::BoundingBox do
  subject { RGeoServer::BoundingBox.new }

  it 'should reset' do
    subject.to_a.should == [0.0, 0.0, 0.0, 0.0]
    subject << [-1, 1]
    subject.to_a.should == [-1, 1, -1, 1]
    subject.reset
    subject.to_a.should == [0.0, 0.0, 0.0, 0.0]
  end
  
  it 'should handle <<' do
    subject << [-1, 1]
    subject.to_a.should == [-1, 1, -1, 1]
  end

  it 'should add point' do
    subject.add -1, 0
    subject.to_a.should == [-1, 0, -1, 0]
    subject.add -1, -1
    subject.to_a.should == [-1, -1, -1, 0]
    subject.add 1, -1
    subject.to_a.should == [-1, -1, 1, 0.0]
    subject.add 1, 1
    subject.to_a.should == [-1, -1, 1, 1]
  end

  it 'should expand with default' do
    e = RGeoServer::BoundingBox.epsilon
    subject.add 1, 2
    subject.expand
    subject.to_a.should == [1 - e, 2 - e, 1 + e, 2 + e]
  end

  it 'should constrict with default' do
    e = RGeoServer::BoundingBox.epsilon
    subject.add 1, 2
    subject.constrict
    subject.to_a.should == [1 - e, 2 - e, 1 + e, 2 + e]
  end

  it 'should expand with rate' do
    rate = 5
    subject.add 1, 2
    subject.expand rate
    subject.to_a.should == [1 - rate, 2 - rate, 1 + rate, 2 + rate]
  end

  it 'should constrict with rate' do
    rate = 5
    subject.add 1, 2
    subject.constrict rate
    subject.to_a.should == [1 - rate, 2 - rate, 1 + rate, 2 + rate]
  end

  it 'should constrict having non-zero area' do
    rate = 0.2
    subject.add -1, -2
    subject.add 3, 4
    subject.constrict rate
    subject.to_a.should == [-1 + rate, -2 + rate, 3 - rate, 4 - rate]
  end

  it 'should generate geometry with different points' do
    subject.add -1, -2
    subject.add 3, 4
    polygon = subject.to_geometry
    polygon.geometry_type.should == RGeo::Feature::Polygon
    polygon.as_text.should ==
      "POLYGON ((-1.0 -2.0, 3.0 -2.0, 3.0 4.0, -1.0 4.0, -1.0 -2.0))"
  end

  it 'should generate geometry with same points using delta' do
    subject.add 1, 2
    polygon = subject.to_geometry
    polygon.geometry_type.should == RGeo::Feature::Polygon
    # assuming epsilon == 0.0001
    RGeoServer::BoundingBox.epsilon.should == 0.0001
    polygon.as_text.should == 
      "POLYGON ((0.9999 1.9999, 1.0001 1.9999, 1.0001 2.0001, 0.9999 2.0001, 0.9999 1.9999))"
  end
  
  it 'setting epsilon' do
    RGeoServer::BoundingBox.epsilon.should == 0.0001
    RGeoServer::BoundingBox.epsilon = 0.1
    RGeoServer::BoundingBox.epsilon.should == 0.1
    RGeoServer::BoundingBox.epsilon = 0.0001
    RGeoServer::BoundingBox.epsilon.should == 0.0001
  end
  
  it 'from_a' do
    bb = RGeoServer::BoundingBox.from_a([1, 2, 3, 4])
    bb.to_a.should == [1, 2, 3, 4]
  end

  it 'nesw' do
    bb = RGeoServer::BoundingBox.from_a([1, 2, 3, 4])
    bb.n.should == 4
    bb.e.should == 3
    bb.s.should == 2
    bb.w.should == 1
    bb.ne.should == [3, 4]
    bb.sw.should == [1, 2]
  end

  it 'valid?' do
    subject.valid?.should == false
    bb = RGeoServer::BoundingBox.from_a([1, 2, 3, 4])
    bb.valid?.should == true
  end
end
