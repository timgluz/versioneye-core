require 'spec_helper'
require 'vcr'
require 'webmock'

# require 'capybara/rails'
require 'capybara/rspec'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes/'
  c.ignore_localhost = true
  c.hook_into :webmock
end


describe SyncService do

  describe 'sync_product' do

    it 'syncs junit' do
      Product.count.should == 0
      VCR.use_cassette('sync_product_junit', allow_playback_repeats: true) do
        SyncService.sync_product 'Java', 'junit/junit'
      end
      Product.count.should == 1
    end

  end


  describe 'sync_security' do

    it 'syncs sv' do
      env     = Settings.instance.environment
      GlobalSetting.set env, 'api_key', 'b7f7c65e66d38f511'

      expect( Product.count ).to eq(0)
      expect( SecurityVulnerability.count ).to eq(0)
      VCR.use_cassette('sync_security_aws', allow_playback_repeats: true) do
        SyncService.sync_product 'PHP', 'aws/aws-sdk-php'
      end
      expect( SecurityVulnerability.count ).to eq(1)
      expect( SecurityVulnerability.first.language ).to eq('PHP')
      expect( SecurityVulnerability.first.prod_key ).to eq('aws/aws-sdk-php')
      expect( SecurityVulnerability.first.name_id ).to eq('2015-08-31')
      expect( SecurityVulnerability.first.summary ).to eq('Security Misconfiguration Vulnerability in the AWS SDK for PHP')
      expect( SecurityVulnerability.first.cve ).to eq('CVE-2015-5723')
      expect( SecurityVulnerability.first.affected_versions.count > 0 ).to be_truthy
      expect( Product.count ).to eq(1)
      expect( Product.first.version_by_number('3.0.0').sv_ids.count ).to eq(1)
      expect( Product.first.version_by_number('3.2.0').sv_ids.count ).to eq(1)
      expect( Product.first.version_by_number('3.3.0').sv_ids.count ).to eq(0)
    end

  end


  describe 'sync_project' do

    it 'syncs projects' do
      env     = Settings.instance.environment
      GlobalSetting.set env, 'api_key', 'MY_API_TEST_KEY'

      user = UserFactory.create_new
      project = ProjectFactory.create_new user
      expect(project.save).to be_truthy

      pdep1 = Projectdependency.new({:language => 'Ruby', :name => 'vcr', :project_id => project.ids})
      expect( pdep1.save ).to be_truthy
      pdep2 = Projectdependency.new({:language => 'Ruby', :name => 'log4r', :project_id => project.ids})
      expect( pdep2.save ).to be_truthy

      expect( project.projectdependencies.count ).to eq(2)

      Product.count.should == 0
      VCR.use_cassette('sync_project_log4r', allow_playback_repeats: true) do
        SyncService.sync_project project
      end
      Product.count.should == 2
    end

  end


  describe 'sync' do

    it 'syncs all projectdependencies' do
      user = UserFactory.create_new 1067
      user.nil?.should be_falsey
      project = ProjectFactory.create_new user

      product_1 = ProductFactory.create_for_gemfile 'log4r', '0.0.0'
      product_1.save

      product_2 = ProductFactory.create_for_gemfile 'vcr', '0.0.0'
      product_2.save

      dep_1 = ProjectdependencyFactory.create_new project, product_1
      dep_2 = ProjectdependencyFactory.create_new project, product_2

      product_1.versions.count.should == 1
      product_2.versions.count.should == 1
      Product.count.should == 2
      Projectdependency.count.should == 2

      VCR.use_cassette('sync_project_log4r', allow_playback_repeats: true) do
        SyncService.sync
      end
      Product.count.should == 2
      prod = Product.last
      prod.versions.count > 4
    end

  end

end
