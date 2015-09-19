require 'spec_helper'

describe LicenseCach do

  describe 'to_s' do
    it 'returns to_s string' do
      license = LicenseCach.new({:name => 'list', :url => 'http://www.versioneye.com', :on_whitelist => true})
      expect(license.to_s).to eq('true - list - http://www.versioneye.com')
    end
  end

  describe 'link and url' do
    it 'returns same value for link and url' do
      license = LicenseCach.new({:url => 'http://www.versioneye.com'})
      expect( license.link ).to eq( license.url )
    end
  end

  describe 'name and namesubstitute' do
    it 'returns same value for link and url' do
      license = LicenseCach.new({:name => 'my_name'})
      expect( license.name ).to eq( license.name_substitute )
    end
  end

  describe 'is_whitelisted?' do
    it 'returns true' do
      license = LicenseCach.new({:on_whitelist => true})
      expect( license.is_whitelisted? ).to be_truthy
    end
    it 'returns true' do
      license = LicenseCach.new({:on_cwl => true})
      expect( license.is_whitelisted? ).to be_truthy
    end
    it 'returns true' do
      license = LicenseCach.new({:on_cwl => true, :on_whitelist => true})
      expect( license.is_whitelisted? ).to be_truthy
    end
    it 'returns true' do
      license = LicenseCach.new({:on_cwl => true, :on_whitelist => false})
      expect( license.is_whitelisted? ).to be_truthy
    end
    it 'returns true' do
      license = LicenseCach.new({:on_cwl => false, :on_whitelist => true})
      expect( license.is_whitelisted? ).to be_truthy
    end
    it 'returns false' do
      license = LicenseCach.new()
      expect( license.is_whitelisted? ).to be_falsey
    end
    it 'returns false' do
      license = LicenseCach.new({:on_cwl => false, :on_whitelist => false})
      expect( license.is_whitelisted? ).to be_falsey
    end
    it 'returns nil' do
      license = LicenseCach.new({:on_cwl => nil, :on_whitelist => nil})
      expect( license.is_whitelisted? ).to be_nil
    end
  end

end
