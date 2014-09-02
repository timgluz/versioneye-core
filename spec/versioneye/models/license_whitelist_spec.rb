require 'spec_helper'

describe LicenseWhitelist do

  describe 'to_s' do
    it 'returns the name' do
      license = LicenseWhitelist.new({:name => 'MIT'})
      expect(license.to_s).to eq('MIT')
    end
  end

  describe 'to_param' do
    it 'returns the name' do
      license = LicenseWhitelist.new({:name => 'MIT'})
      expect(license.to_param).to eq('MIT')
    end
  end

  describe 'find_by' do
    it 'returns the search element' do
      user = UserFactory.create_new
      license = LicenseWhitelist.new({:name => 'MIT'})
      license.user = user
      license.save
      lw = LicenseWhitelist.fetch_by user, 'MIT'
      expect(license).not_to be_nil
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

  describe 'add_license_element' do
    it 'adds 1 element' do
      license = LicenseWhitelist.new :name => 'OpenSource'
      expect( license.license_elements_empty? ).to be_truthy
      license.add_license_element( 'MIT' )
      expect( license.license_elements_empty? ).to be_falsy
      expect( license.license_elements.size ).to eq(1)
      expect( license.license_elements.count ).to eq(0)
      license.save
      expect( license.license_elements.count ).to eq(1)
    end
    it 'adds 2 element, but only stores 1 because uniq' do
      license = LicenseWhitelist.new :name => 'OpenSource'
      expect( license.license_elements_empty? ).to be_truthy
      license.add_license_element( 'MIT' )
      license.add_license_element( 'MIT' )
      expect( license.license_elements_empty? ).to be_falsy
      expect( license.license_elements.size ).to eq(1)
      expect( license.license_elements.count ).to eq(0)
      license.save
      expect( license.license_elements.count ).to eq(1)
    end
    it 'adds 2 element' do
      license = LicenseWhitelist.new :name => 'OpenSource'
      expect( license.license_elements_empty? ).to be_truthy
      license.add_license_element( 'MIT' )
      license.add_license_element( 'Ruby' )
      expect( license.license_elements_empty? ).to be_falsy
      expect( license.license_elements.size ).to eq(2)
      expect( license.license_elements.count ).to eq(0)
      license.save
      expect( license.license_elements.count ).to eq(2)
    end
  end

end
