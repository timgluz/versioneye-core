require 'spec_helper'

describe Version do

  describe 'encode_version' do

    it 'it encodes like expected' do
      Version.encode_version('12/dev-master').should eql('12:dev-master')
    end

    it 'it encodes like expected' do
      Version.encode_version('1.2.3').should eql('1.2.3')
    end

  end

  describe 'decode_version' do

    it 'it decodes like expected' do
      Version.decode_version('12:dev-master').should eql('12/dev-master')
    end

    it 'it decodes like expected' do
      Version.decode_version('1.2.3').should eql('1.2.3')
    end

  end

  describe 'to_param' do

    it 'returns the encoded version' do
      Version.new({:version => '12/dev-master '}).to_param.should eql('12:dev-master')
    end

    it 'it encodes like expected' do
      Version.new({:version => '1.2.3'}).to_param.should eql('1.2.3')
    end

  end

  describe 'to_s' do

    it 'returns the version' do
      Version.new({:version => '12/dev-master'}).to_s.should eql('12/dev-master')
    end

  end

  describe 'eql?' do

    it 'is true' do
      a = Version.new({:version => '1.0.0'})
      Version.new({:version => '1.0.0'}).eql?(a).should be_truthy
    end
    it 'is false' do
      a = Version.new({:version => '1.0.1'})
      Version.new({:version => '1.0.0'}).eql?(a).should be_falsey
    end

  end

  describe 'released_or_detected' do

    it 'returns the released date' do
      released = DateTime.now
      Version.new({:version => '12/dev-master', :released_at => released }).released_or_detected.should eql(released)
    end

    it 'returns the created date' do
      product = ProductFactory.create_new
      version = Version.new({:version => '12/dev-master'})
      product.versions.push version
      product.save
      version.save
      created = version.created_at
      expect( created ).to_not be_nil
      version.released_or_detected.should_not be_nil
    end

  end

end
