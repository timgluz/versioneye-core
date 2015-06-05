require 'spec_helper'

describe ProjectdependencyService do

  before(:each) do
    user              = UserFactory.create_new

    @project          = ProjectFactory.create_new( user )
    @project.language = Product::A_LANGUAGE_RUBY

    @product          = Product.new({:prod_type => Project::A_TYPE_RUBYGEMS, :language => Product::A_LANGUAGE_RUBY, :prod_key => 'gomezify', :name => 'gomezify'})
    @product.versions = Array.new
    @product.versions.push(Version.new({:version => '1.0'}))
    @product.version  = @product.versions.first.to_s
    @product.save
  end

  describe "update_licenses" do
    it 'updates the dependencies with the license infos' do
      Projectdependency.count.should eq(0)
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_current   = @product.version
      dep.version_requested = @product.version
      dep.save 
      Projectdependency.count.should eq(1)
      @project.dependencies.count.should eq(1)
      
      license = LicenseFactory.create_new @product, "MIT"
      license.save 
      dep.license_caches.should be_empty 

      ProjectdependencyService.update_licenses @project 

      dep = Projectdependency.first
      dep.license_caches.should_not be_empty 
      dep.license_caches.count.should eq(1)
      dep.license_caches.first.name.should eq('MIT')
    end
  end

  describe "update_security" do

    it 'updates the dependencies with the securiyt infos' do
      Projectdependency.count.should eq(0)
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_current   = @product.version
      dep.version_requested = @product.version
      dep.save 
      Projectdependency.count.should eq(1)
      @project.dependencies.count.should eq(1)
      
      sv = SecurityVulnerability.new({:language => @product.language, :prod_key => @product.prod_key, :summary => 'test'})
      sv.affected_versions << @product.version 
      sv.save.should be_truthy
      
      version = @product.version_by_number @product.version 
      version.sv_ids << sv._id.to_s 
      version.save.should be_truthy

      @project.sv_count.should eq(0)

      ProjectdependencyService.update_security @project 

      @project.sv_count.should eq(1)
      dep = Projectdependency.first
      dep.sv_ids.should_not be_empty 
      dep.sv_ids.count.should eq(1)
      dep.sv_ids.first.to_s.should eq( sv._id.to_s )
    end

  end

  describe "release?" do

    it 'returns nil because parameter is nil' do
      ProjectdependencyService.release?(nil).should be_nil
    end

    it 'returns nil because version_current is nil' do
      ProjectdependencyService.release?(Projectdependency.new).should be_nil
    end

    it 'updates the release to true' do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_current = @product.version
      dep.release.should be_nil
      ProjectdependencyService.release?(dep).should_not be_nil
      dep.release.should_not be_nil
      dep.release.should be_truthy
    end

    it 'updates the release to false' do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_current = '1.1.2-Alpha'
      dep.release.should be_nil
      ProjectdependencyService.release?(dep).should_not be_nil
      dep.release.should_not be_nil
      dep.release.should be_falsey
    end

  end

  describe "outdated?" do

    it "returns nil for nil" do
      ProjectdependencyService.outdated?(nil).should be_nil
    end

    it "is up to date" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "1.0"
      ProjectdependencyService.outdated?( dep ).should be_falsey
      dep.unknown?.should be_falsey
    end

    it "is outdated" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "0.9"
      ProjectdependencyService.outdated?( dep ).should be_truthy
      dep.unknown?.should be_falsey
    end

    it "is up-to-date because its muted" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "0.9"
      dep.muted = true
      dep.save
      ProjectdependencyService.outdated?( dep ).should be_falsey
      dep.unknown?.should be_falsey
    end

    it "is up to date" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "1.9"
      ProjectdependencyService.outdated?(dep).should be_falsey
      dep.unknown?.should  be_falsey
    end

    it "is up to date because it is GIT" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "GIT"
      ProjectdependencyService.outdated?(dep).should be_falsey
    end

    it "is up to date because it is PATH" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "PATH"
      ProjectdependencyService.outdated?(dep).should be_falsey
    end

    it "is up to date because it is unknown" do
      dep = ProjectdependencyFactory.create_new(@project, nil)
      dep.version_requested = "2.0.0"
      ProjectdependencyService.outdated?(dep).should be_falsey
      dep.unknown?.should  be_truthy
    end

    it "is up to date" do
      prod_key           = "symfony/locale_de"
      product            = ProductFactory.create_for_composer(prod_key, "2.2.x-dev")
      product.versions.push( Version.new({:version => '2.2.1'}) )
      product.language   = Product::A_LANGUAGE_PHP
      product.save

      dep                   = Projectdependency.new({ :prod_key => product.prod_key })
      dep.version_requested = "2.2.x-dev"
      dep.stability         = "dev"
      dep.language          = Product::A_LANGUAGE_PHP

      ProjectdependencyService.outdated?(dep).should be_falsey
      dep.version_current.should eql("2.2.x-dev")
    end

    it "is up to date" do
      prod_key           = "rails"
      product            = ProductFactory.create_for_gemfile(prod_key, "3.2.13")
      version_01         = Version.new
      version_01.version = "3.2.13"
      product.versions.push( version_01 )
      product.language   = Product::A_LANGUAGE_RUBY
      product.save

      dep                   = Projectdependency.new
      dep.prod_key          = "rails"
      dep.version_requested = "3.2.13"
      dep.language          = Product::A_LANGUAGE_RUBY
      dep.stability         = VersionTagRecognizer.stability_tag_for dep.version_requested
      ProjectdependencyService.outdated?( dep ).should be_falsey
    end

    it "is not up to date" do
      prod_key           = "rails"
      product            = ProductFactory.create_for_gemfile(prod_key, "3.2.13")
      version_01         = Version.new
      version_01.version = "3.2.13-rc1"
      product.versions.push( version_01 )
      product.language   = Product::A_LANGUAGE_RUBY
      product.save

      dep                   = Projectdependency.new
      dep.prod_key          = "rails"
      dep.version_requested = "3.2.13-rc1"
      dep.language          = Product::A_LANGUAGE_RUBY
      dep.stability         = VersionTagRecognizer.stability_tag_for dep.version_requested
      ProjectdependencyService.outdated?( dep ).should be_truthy
    end

    it "checks the cache" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "1.0"
      ProjectdependencyService.outdated?(dep).should be_falsey
      dep.unknown?.should  be_falsey

      dep.version_requested = "0.1"
      dep.release = nil
      ProjectdependencyService.outdated?(dep).should be_falsey
      ProjectdependencyService.update_outdated!(dep)
      ProjectdependencyService.outdated?(dep).should be_truthy
      dep.release.should_not be_nil
      dep.release.should be_truthy
    end


    it "checks if the cache updates after a time period" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = "1.0"
      ProjectdependencyService.outdated?(dep).should be_falsey
      dep.unknown?.should be_falsey

      dep.version_requested = "0.1"
      dep.release = nil
      dep.save
      # Should fetch value from catch and return false
      ProjectdependencyService.outdated?(dep).should be_falsey

      day_before = dep.outdated_updated_at - 1
      dep.outdated_updated_at = day_before
      dep.save

      # Should update the cached value and return true
      ProjectdependencyService.outdated?(dep).should be_truthy
      dep.release.should_not be_nil
      dep.release.should be_truthy
    end

  end

  describe "update_version_current" do

    it "doesnt update because prod_key is nil" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.prod_key          = nil
      dep.version_requested = '0.1'
      dep.version_current   = nil
      ProjectdependencyService.update_version_current( dep )
      dep.version_current.should eq(nil)
    end

    it "doesnt update because prod_key is empty" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.prod_key          = ''
      dep.version_requested = '0.1'
      dep.version_current   = nil
      ProjectdependencyService.update_version_current( dep )
      dep.version_current.should eq(nil)
    end

    it "doesnt update because prod_key, group_id and artifact_id are unknown" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.prod_key          = 'gibts_doch_net'
      dep.group_id          = 'gibts_doch_net'
      dep.artifact_id       = 'gibts_doch_net'
      dep.version_requested = '0.1'
      dep.version_current   = nil
      ProjectdependencyService.update_version_current( dep )
      dep.version_current.should eq(nil)
    end

    it "updates with the current verson" do
      dep                   = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_requested = '0.1'
      ProjectdependencyService.update_version_current( dep )
      dep.version_current.should eq('1.0')
    end

    it "updates with the current verson from different language" do
      user = UserFactory.create_new

      project          = ProjectFactory.create_new( user )
      project.language = Product::A_LANGUAGE_JAVA

      product          = Product.new({:name => 'lamina', :prod_key => 'lamina', :group_id => 'lamina', :artifact_id => 'lamina', :language => Product::A_LANGUAGE_CLOJURE, :prod_type => Project::A_TYPE_LEIN })
      product.versions = Array.new
      product.versions.push(Version.new({:version => '1.0'}))
      product.version  = product.versions.first.to_s
      product.save

      dep = ProjectdependencyFactory.create_new(project, product)
      dep.language          = Product::A_LANGUAGE_JAVA
      dep.version_requested = '0.1'
      ProjectdependencyService.update_version_current( dep )
      dep.version_current.should eq('1.0')
    end

  end

  describe 'mute!' do

    it 'does not mute because project does not exist' do
      ProjectdependencyService.mute!( 'does_not_exist', 'does_not_exist', true ).should be_falsey
    end

    it 'does not mute because project has no dependencies' do
      user    = UserFactory.create_new
      project = ProjectFactory.create_new( user )
      ProjectdependencyService.mute!( project.id.to_s, 'does_not_exist', true ).should be_falsey
    end

    it 'does mute like expected' do
      user    = UserFactory.create_new 45 
      expect( user.save ).to be_truthy

      project = ProjectFactory.create_new( user )
      project.source = Project::A_SOURCE_UPLOAD 
      expect( project.save ).to be_truthy
      
      product = ProductFactory.create_for_gemfile 'rails', '1.0.0'
      expect( product.save ).to be_truthy
      
      dependency = ProjectdependencyFactory.create_new(project, product)
      dependency.project_id = project.ids 
      dependency.version_label = '0.9.0'
      dependency.version_requested = '0.9.0'
      dependency.version_current = '0.9.0'
      dependency.outdated = true 
      expect( dependency.save ).to be_truthy
      expect( dependency.muted ).to be_falsey
      expect( dependency.outdated ).to be_truthy
      expect( ProjectService.outdated?(project) ).to be_truthy

      project = ProjectUpdateService.update project  
      expect( project ).to_not be_nil 
      expect( project.dependencies.count ).to eq(1)
      expect( project.dep_number ).to eq(1)
      expect( project.out_number ).to eq(1)
      expect( project.out_number_sum ).to eq(1)

      expect( ProjectdependencyService.mute!( project.id.to_s, dependency.id.to_s, true ) ).to be_truthy
      dependency.reload
      expect( dependency.muted ).to be_truthy
      expect( dependency.outdated ).to be_falsey
      project.reload 
      expect( project.out_number ).to eq(0)
      expect( project.out_number_sum ).to eq(0)
      expect( ProjectService.outdated?(project) ).to be_falsey

      expect( ProjectdependencyService.mute!( project.id.to_s, dependency.id.to_s, false ) ).to be_truthy
      dependency.reload
      expect( dependency.muted ).to be_falsey
      expect( dependency.outdated ).to be_truthy
      project.reload 
      expect( project.out_number ).to eq(1)
      expect( project.out_number_sum ).to eq(1)
      expect( ProjectService.outdated?(project) ).to be_truthy
    end

  end

end

