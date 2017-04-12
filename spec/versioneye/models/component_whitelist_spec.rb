require 'spec_helper'

describe ComponentWhitelist do

  before(:each) do
    Plan.create_defaults
    @user1 = UserFactory.create_new
    @orga = OrganisationService.create_new_for @user1
    expect( @orga.save ).to be_truthy
  end

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
      orga = Organisation.new :name => 'orga'
      cwl = ComponentWhitelist.new({:name => 'MIT', :organisation => @orga})
      cwl.organisation = orga
      cwl.save
      lw = ComponentWhitelist.fetch_by orga, 'MIT'
      expect(cwl).not_to be_nil
    end
  end

  describe 'is_on_list?' do
    it 'returns true because on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT', :organisation => @orga})
      cwl.add "junit:junit"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("junit:junit") ).to be_truthy
    end
    it 'returns true because on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT', :organisation => @orga})
      cwl.add "junit:junit"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("junit:junit:2.0") ).to be_truthy
    end
    it 'returns true because on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT', :organisation => @orga})
      cwl.add "net.sf.jasperreports:jasperreports:3.6.0"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("net.sf.jasperreports:jasperreports:3.6.0") ).to be_truthy
    end
    it 'returns true because on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT', :organisation => @orga})
      cwl.add "net.sf.jasperreports"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("net.sf.jasperreports:jasperreports-core:4.6.0") ).to be_truthy
    end
    it 'returns true because on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT', :organisation => @orga})
      cwl.add "org.apache"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("org.apache.maven:maven-core:4.6.0") ).to be_truthy
    end
    it 'returns false because not on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT', :organisation => @orga})
      cwl.add "net.sf.jasperreports:jasperreports:3.6.0"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("net.sf.jasperreports:jasperreports:3.6.1") ).to be_falsey
    end
    it 'returns true because not on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT', :organisation => @orga})
      cwl.add "net.sf.jasperreports:jasperreports"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("net.sf.jasperreports:jasperreports-core:3.6.1") ).to be_truthy
    end
    it 'returns false because not on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT', :organisation => @orga})
      cwl.add "net.sf.jasperreports:jasperreports:"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("net.sf.jasperreports:jasperreports-core:3.6.1") ).to be_falsey
    end
    it 'returns false because not on list' do
      cwl = ComponentWhitelist.new({:name => 'MIT', :organisation => @orga})
      cwl.add "net.sf.jasperreports:jasperreports"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("com.sf.jasperreports:jasperreports:3.6.1") ).to be_falsey
    end
    it 'returns true because on list' do
      cwl = ComponentWhitelist.new({:name => 'MyComps', :organisation => @orga})
      cwl.add "php:wpackagist-plugin"
      expect( cwl.save ).to be_truthy
      expect( cwl.is_on_list?("php:wpackagist-plugin/onelogin-saml-sso") ).to be_truthy
    end
  end

  describe 'auditlogs' do
    it 'returns the auditlogs' do
      user = UserFactory.create_new
      orga = Organisation.new :name => 'orga'
      cwl = ComponentWhitelist.new({:name => 'CWL'})
      cwl.organisation = orga
      expect( cwl.save ).to be_truthy
      Auditlog.add(user, "ComponentWhitelist", cwl.id.to_s, 'Added junit:junit')
      expect( cwl.auditlogs ).to_not be_nil
      expect( cwl.auditlogs.count ).to eq(1)
    end
  end

  describe 'add' do
    it 'adds some elements' do
      orga = Organisation.new :name => 'orga'
      cwl = ComponentWhitelist.new({:name => 'CWL'})
      cwl.organisation = orga
      expect( cwl.save ).to be_truthy
      cwl.add "junit:junit"
      expect( cwl.save ).to be_truthy
      cwl = ComponentWhitelist.first
      expect( cwl.components.first ).to eq("junit:junit")
    end
    it 'adds the same elements twice' do
      orga = Organisation.new :name => 'orga'
      cwl = ComponentWhitelist.new({:name => 'CWL'})
      cwl.organisation = orga
      expect( cwl.save ).to be_truthy
      cwl.add "junit:junit"
      cwl.add "junit:junit"
      expect( cwl.save ).to be_truthy
      cwl = ComponentWhitelist.first
      expect( cwl.components.count ).to eq(1)
      expect( cwl.components.first ).to eq("junit:junit")
    end
  end

  describe 'remove' do
    it 'adds some elements' do
      orga = Organisation.new :name => 'orga'
      cwl = ComponentWhitelist.new({:name => 'CWL'})
      cwl.organisation = orga
      cwl.add "junit:junit"
      cwl.save
      cwl.remove "junit:junit"
      cwl.save
      cwl = ComponentWhitelist.first
      expect( cwl.components.empty? ).to be_truthy
    end
  end

end
