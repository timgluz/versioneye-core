require 'spec_helper'

describe ComponentWhitelist do

  describe 'to_s' do
    it 'returns the name' do
      license = ComponentWhitelist.new({:name => 'MIT'})
      expect(license.to_s).to eq('MIT')
    end
  end

  describe 'to_param' do
    it 'returns the name' do
      license = ComponentWhitelist.new({:name => 'MIT'})
      expect(license.to_param).to eq('MIT')
    end
  end

  describe 'update_from' do
    it 'updates from params' do
      params = {:name => 'MIT'}
      license = ComponentWhitelist.new
      expect( license.name ).to be_nil
      license.update_from params
      expect( license.name ).to eq('MIT')
    end
  end

  describe 'find_by' do
    it 'returns the search element' do
      user = UserFactory.create_new
      license = ComponentWhitelist.new({:name => 'MIT'})
      license.user = user
      license.save
      lw = ComponentWhitelist.fetch_by user, 'MIT'
      expect(license).not_to be_nil
    end
  end

  describe 'is_on_list?' do
    it 'returns true because on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT'})
      cwl.add "junit::junit"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("junit::junit") ).to be_truthy
    end
    it 'returns true because on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT'})
      cwl.add "junit::junit"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("junit::junit::2.0") ).to be_truthy
    end
    it 'returns true because on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT'})
      cwl.add "net.sf.jasperreports::jasperreports::3.6.0"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("net.sf.jasperreports::jasperreports::3.6.0") ).to be_truthy
    end
    it 'returns true because on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT'})
      cwl.add "net.sf.jasperreports"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("net.sf.jasperreports::jasperreports-core::4.6.0") ).to be_truthy
    end
    it 'returns false because not on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT'})
      cwl.add "net.sf.jasperreports::jasperreports::3.6.0"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("net.sf.jasperreports::jasperreports::3.6.1") ).to be_falsey
    end
    it 'returns false because not on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT'})
      cwl.add "net.sf.jasperreports::jasperreports"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("net.sf.jasperreports::jasperreports-core::3.6.1") ).to be_falsey
    end
    it 'returns false because not on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT'})
      cwl.add "net.sf.jasperreports::jasperreports"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("com.sf.jasperreports::jasperreports::3.6.1") ).to be_falsey
    end
  end

  describe 'auditlogs' do
    it 'returns the auditlogs' do
      user = UserFactory.create_new
      cwl = ComponentWhitelist.new({:name => 'CWL'})
      cwl.user = user
      cwl.save
      Auditlog.add(user, "ComponentWhitelist", cwl.id.to_s, 'Added junit:junit')
      expect( cwl.auditlogs ).to_not be_nil
      expect( cwl.auditlogs.count ).to eq(1)
    end
  end

  describe 'add' do
    it 'adds some elements' do
      user = UserFactory.create_new
      cwl = ComponentWhitelist.new({:name => 'CWL'})
      cwl.user = user
      expect( cwl.save ).to be_truthy
      cwl.add "junit::junit"
      expect( cwl.save ).to be_truthy
      cwl = ComponentWhitelist.first
      expect( cwl.components.first ).to eq("junit::junit")
    end
    it 'adds the same elements twice' do
      user = UserFactory.create_new
      cwl = ComponentWhitelist.new({:name => 'CWL'})
      cwl.user = user
      expect( cwl.save ).to be_truthy
      cwl.add "junit::junit"
      cwl.add "junit::junit"
      expect( cwl.save ).to be_truthy
      cwl = ComponentWhitelist.first
      expect( cwl.components.count ).to eq(1)
      expect( cwl.components.first ).to eq("junit::junit")
    end
  end

  describe 'remove' do
    it 'adds some elements' do
      user = UserFactory.create_new
      cwl = ComponentWhitelist.new({:name => 'CWL'})
      cwl.user = user
      cwl.add "junit::junit"
      cwl.save
      cwl.remove "junit::junit"
      cwl.save
      cwl = ComponentWhitelist.first
      expect( cwl.components.empty? ).to be_truthy
    end
  end

end
