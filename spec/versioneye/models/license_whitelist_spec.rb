require 'spec_helper'

describe LicenseWhitelist do

  describe 'to_s' do
    it 'returns the name' do
      license = LicenseWhitelist.new({:name => 'MIT'})
      expect(license.to_s).to eq('MIT')
    end
  end

  describe 'update_from' do
    it 'updates from params' do
      params = {:name => 'MIT'}
      license = LicenseWhitelist.new
      expect( license.name ).to be_nil
      license.update_from params
      expect( license.name ).to eq('MIT')
    end
  end

  describe 'name_substitute' do
    it 'substitutes the name' do
      license = LicenseWhitelist.new :name => 'Ruby license'
      expect( license.name_substitute ).to eq('Ruby')
    end
  end

end
