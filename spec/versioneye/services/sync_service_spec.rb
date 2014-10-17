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


  describe 'sync_project' do

    it 'syncs projects' do
      project = Project.new
      project.projectdependencies << Projectdependency.new({:language => 'Ruby', :name => 'vcr'})
      project.projectdependencies << Projectdependency.new({:language => 'Ruby', :name => 'log4r'})

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
