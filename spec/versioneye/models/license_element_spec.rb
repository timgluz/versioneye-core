require 'spec_helper'

describe LicenseElement do

  describe 'to_s' do
    it 'returns the name' do
      license = LicenseElement.new({:name => 'MIT'})
      expect(license.to_s).to eq('MIT')
    end
  end

  describe 'to_param' do
    it 'returns the name' do
      license = LicenseElement.new({:name => 'MIT'})
      expect(license.to_param).to eq('MIT')
    end
  end

end
