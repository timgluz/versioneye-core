require 'spec_helper'

describe ProjectdependencyService do

  before(:each) do
    Plan.create_defaults

    @user              = UserFactory.create_new
    expect( @user.save ).to be_truthy

    @orga             = OrganisationService.create_new_for(@user)
    expect(@orga.save).to be_truthy

    @project          = ProjectFactory.create_new( @user, nil, true, @orga )
    @project.language = Product::A_LANGUAGE_RUBY

    @product          = Product.new({:prod_type => Project::A_TYPE_RUBYGEMS, :language => Product::A_LANGUAGE_RUBY, :prod_key => 'gomezify', :name => 'gomezify'})
    @product.versions = Array.new
    @product.versions.push(Version.new({:version => '1.0'}))
    @product.version  = @product.versions.first.to_s
    expect( @product.save ).to be_truthy
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
      expect( license.save ).to be_truthy

      dep.license_caches.should be_empty

      ProjectdependencyService.update_licenses @project

      dep = Projectdependency.first
      expect( dep.license_caches ).to_not be_empty
      expect( dep.license_caches.count).to eq(1)
      expect( dep.license_caches.first.name).to eq('MIT')
      expect( dep.license_caches.first.on_whitelist).to be_nil
    end

    it 'updates the dependencies with the license infos, dependency is conform with lwl' do
      expect( Projectdependency.count ).to eq(0)
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_current   = @product.version
      dep.version_requested = @product.version
      expect( dep.save ).to be_truthy
      expect( Projectdependency.count ).to eq(1)

      license = LicenseFactory.create_new @product, "MIT"
      expect( license.save ).to be_truthy

      lwl = LicenseWhitelistFactory.create_new 'MY_SECRET_WHITELIST', ['mit'], @user, @orga
      expect( lwl.save ).to be_truthy

      @project.license_whitelist_id = lwl.ids
      expect( @project.save ).to be_truthy

      ProjectdependencyService.update_licenses @project

      dep = Projectdependency.first
      expect( dep.license_caches ).to_not be_empty
      expect( dep.license_caches.count).to eq(1)
      expect( dep.license_caches.first.name).to eq('MIT')
      expect( dep.license_caches.first.on_whitelist).to_not be_nil
      expect( dep.license_caches.first.on_whitelist).to be_truthy
      expect( dep.license_caches.first.is_whitelisted?).to be_truthy
    end

    it 'updates the dependencies with the license infos, dependency violates lwl' do
      Projectdependency.count.should eq(0)
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_current   = @product.version
      dep.version_requested = @product.version
      dep.save
      Projectdependency.count.should eq(1)

      license = LicenseFactory.create_new @product, "GPL-3.0"
      expect( license.save ).to be_truthy

      lwl = LicenseWhitelistFactory.create_new 'MY_SECRET_WHITELIST', ['mit'], @user, @orga
      lwl.save
      @project.license_whitelist_id = lwl.ids
      @project.save

      ProjectdependencyService.update_licenses @project

      dep = Projectdependency.first
      expect( dep.license_caches ).to_not be_empty
      expect( dep.license_caches.count).to eq(1)
      expect( dep.license_caches.first.name).to eq('GPL-3.0')
      expect( dep.license_caches.first.on_whitelist).to_not be_nil
      expect( dep.license_caches.first.on_whitelist).to be_falsey
      expect( dep.license_caches.first.is_whitelisted?).to be_falsey
    end

    it 'updates the dependencies with the license infos, dependency violates lwl but is on cwl' do
      Projectdependency.count.should eq(0)
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_current   = @product.version
      dep.version_requested = @product.version
      dep.save
      Projectdependency.count.should eq(1)

      license = LicenseFactory.create_new @product, "GPL-3.0"
      expect( license.save ).to be_truthy

      lwl = LicenseWhitelistFactory.create_new 'MY_SECRET_WHITELIST', ['mit'], @user, @orga
      lwl.save
      @project.license_whitelist_id = lwl.ids

      cwl = ComponentWhitelist.new({:name => 'my_cwl'})
      cwl.add dep.cwl_key
      cwl.organisation = @orga
      cwl.save
      p cwl.errors
      expect( cwl.save ).to be_truthy
      @project.component_whitelist_id = cwl.ids
      @project.save

      ProjectdependencyService.update_licenses @project

      dep = Projectdependency.first
      expect( dep.license_caches ).to_not be_empty
      expect( dep.license_caches.count).to eq(1)
      expect( dep.license_caches.first.name).to eq('GPL-3.0')
      expect( dep.license_caches.first.on_whitelist).to_not be_nil
      expect( dep.license_caches.first.on_whitelist).to be_falsey
      expect( dep.license_caches.first.on_cwl).to be_truthy
      expect( dep.license_caches.first.is_whitelisted?).to be_truthy
    end

  end

  describe "update_security" do

    it 'updates the dependencies with the security infos' do
      expect( Projectdependency.count ).to eq(0)
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_current   = @product.version
      dep.version_requested = @product.version
      expect( dep.save ).to be_truthy
      expect( Projectdependency.count ).to eq(1)
      expect( @project.dependencies.count ).to eq(1)

      sv = SecurityVulnerability.new({:language => @product.language, :prod_key => @product.prod_key, :summary => 'test'})
      sv.affected_versions << @product.version
      expect( sv.save ).to be_truthy

      version = @product.version_by_number @product.version
      version.sv_ids << sv._id.to_s
      version.sv_ids << "crawling error"
      expect( version.save).to be_truthy
      expect( @project.sv_count).to eq(0)

      ProjectdependencyService.update_security @project

      expect( @project.sv_count).to eq(1)
      dep = Projectdependency.first
      expect( dep.sv_ids).to_not be_empty
      expect( dep.sv_ids.count ).to eq(1)
      expect( dep.sv_ids.first.to_s).to eq( sv._id.to_s )

      # After the 2nd checking the sv_count still should be 1.
      # Testing that the count gets resettet before checking.
      ProjectdependencyService.update_security @project
      @project.reload
      expect( @project.sv_count).to eq(1)
      dep = Projectdependency.first
      expect( dep.sv_ids.count ).to eq(1)
    end

    it 'updates the dependencies with the security infos and muted svs' do
      expect( Projectdependency.count ).to eq(0)
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.version_current   = @product.version
      dep.version_requested = @product.version
      expect( dep.save ).to be_truthy
      expect( Projectdependency.count ).to eq(1)
      expect( @project.dependencies.count ).to eq(1)

      sv = SecurityVulnerability.new({:language => @product.language, :prod_key => @product.prod_key, :summary => 'test', :name_id => "cv2"})
      sv.affected_versions << @product.version
      expect( sv.save ).to be_truthy

      sv2 = SecurityVulnerability.new({:language => @product.language, :prod_key => @product.prod_key, :summary => 'test2', :name_id => "cv1"})
      sv2.affected_versions << @product.version
      expect( sv2.save ).to be_truthy

      version = @product.version_by_number @product.version
      version.sv_ids << sv.ids
      version.sv_ids << sv2.ids
      expect( version.save).to be_truthy
      expect( @project.sv_count).to eq(0)

      ProjectdependencyService.update_security @project

      expect( @project.sv_count).to eq(2)
      dep = Projectdependency.first
      expect( dep.sv_ids).to_not be_empty
      expect( dep.sv_ids.count ).to eq(2)

      @project.mute_security! sv2.ids, 'not important'
      expect( @project.sv_count ).to eq(1)

      # After the 2nd checking the sv_count still should be 1.
      # Testing that the count gets resettet before checking.
      ProjectdependencyService.update_security @project
      @project.reload
      expect( @project.sv_count).to eq(1)
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

    let(:prod1){
      Product.new(
        language: Product::A_LANGUAGE_RUST,
        prod_key: 'serde',
        name: 'serde',
        version: '1.0.8'
      )
    }

    let(:dep1){
      Projectdependency.new(
        language: Product::A_LANGUAGE_RUST,
        prod_key: 'serde_derive',
        version_requested: 'GITHUB',
        version_label: 'serde-rs/serde#fd3d1396d',
        repo_fullname: 'serde-rs/serde',
        repo_ref: 'fd3d1396d33a49200daaaf8bf17eba78fe4183d8'
      )
    }

    let(:auth_token){ Settings.instance.github_client_secret }


    context "dependencies on github" do

      it "returns true when commit date is older than current stable release" do
        prod1.versions << Version.new(
          version: '1.0.8',
          released_at: DateTime.now
        )
        prod1.save

        expect(auth_token).not_to be_nil
        VCR.use_cassette('github/projectdependency_service/by_commit_sha') do
          res = ProjectdependencyService.outdated?(dep1, prod1, auth_token)
          expect(res).to be_truthy
        end
      end

      it "returns false when commit date is newer than current stable release" do
        prod1.versions << Version.new(
          version: '1.0.6',
          released_at: DateTime.parse('2017-05-17')
        )
        prod1.save

        expect(auth_token).not_to be_nil
        VCR.use_cassette('github/projectdependency_service/by_commit_sha') do
          res = ProjectdependencyService.outdated?(dep1, prod1, auth_token)
          expect(res).to be_falsey
        end
      end
    end
  end

  describe "update_version_current" do

    it "doesnt update because prod_key is nil" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.prod_key          = nil
      dep.name              = 'some_random_name_88ask'
      dep.version_requested = '0.1'
      dep.version_current   = nil
      ProjectdependencyService.update_version_current( dep )
      dep.version_current.should eq(nil)
    end

    it "update because name is same as prod_key" do
      dep = ProjectdependencyFactory.create_new(@project, @product)
      dep.prod_key          = nil
      dep.version_requested = '0.1'
      dep.version_current   = nil
      ProjectdependencyService.update_version_current( dep )
      dep.version_current.should eq('1.0')
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

    it 'does mute like expected on a single file project' do
      user    = UserFactory.create_new 45
      expect( user.save ).to be_truthy

      project = ProjectFactory.create_new( user, nil, true, @orga )
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

    it 'does mute like expected on a multi file project' do
      user    = UserFactory.create_new 46
      expect( user.save ).to be_truthy

      project = ProjectFactory.create_new( user, nil, true, @orga )
      project.source = Project::A_SOURCE_UPLOAD
      expect( project.save ).to be_truthy

      project2 = ProjectFactory.create_new( user, nil, false, @orga )
      project2.source = Project::A_SOURCE_UPLOAD
      expect( project2.save ).to be_truthy

      project2.parent_id = project.ids
      expect( project2.save ).to be_truthy

      product = ProductFactory.create_for_gemfile 'rails', '1.0.0'
      expect( product.save ).to be_truthy

      mongoid = ProductFactory.create_for_gemfile 'mongoid', '4.0.0'
      expect( mongoid.save ).to be_truthy

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
      expect( project.dependencies.count ).to eq(1)

      dependency2 = ProjectdependencyFactory.create_new( project2, mongoid )
      dependency2.project_id = project2.ids
      dependency2.version_label = '0.9.0'
      dependency2.version_requested = '0.9.0'
      dependency2.version_current = '4.0.0'
      dependency2.outdated = true
      expect( dependency2.save ).to be_truthy
      expect( dependency2.muted ).to be_falsey
      expect( dependency2.outdated ).to be_truthy
      expect( ProjectService.outdated?( project2 ) ).to be_truthy
      project2.reload
      expect( project2.dependencies.count ).to eq(1)
      expect( project.dependencies.count ).to eq(1)


      project2 = ProjectUpdateService.update project2
      expect( project2 ).to_not be_nil

      expect( project2.dependencies.count ).to eq(1)
      expect( project2.dep_number ).to eq(1)
      expect( project2.out_number ).to eq(1)
      expect( project2.out_number_sum ).to eq(1)


      project = ProjectUpdateService.update project
      expect( project ).to_not be_nil

      expect( project.dependencies.count ).to eq(1)
      expect( project.dep_number ).to eq(1)
      expect( project.out_number ).to eq(1)
      expect( project.out_number_sum ).to eq(2)


      expect( ProjectdependencyService.mute!( project2.ids, dependency2.ids, true ) ).to be_truthy
      dependency2.reload
      expect( dependency2.muted ).to be_truthy
      expect( dependency2.outdated ).to be_falsey
      project2.reload
      expect( project2.out_number ).to eq(0)
      expect( project2.out_number_sum ).to eq(0)
      expect( ProjectService.outdated?(project2) ).to be_falsey

      project.reload
      expect( project.out_number ).to eq(1)
      expect( project.out_number_sum ).to eq(1)
      expect( ProjectService.outdated?(project) ).to be_truthy

      expect( ProjectdependencyService.mute!( project2.id.to_s, dependency2.id.to_s, false ) ).to be_truthy
      dependency.reload
      expect( dependency.muted ).to be_falsey
      expect( dependency.outdated ).to be_truthy
      project2.reload
      expect( project2.out_number ).to eq(1)
      expect( project2.out_number_sum ).to eq(1)
      expect( ProjectService.outdated?(project2) ).to be_truthy
    end
  end

  let(:user1){ UserFactory.create_new }
  let(:orga1){ OrganisationService.create_new_for(user1) }
  let(:project1){ ProjectFactory.create_new( user1, nil, true, orga1 ) }
  let(:sha_head){ "3f7947a25d970e1e5f512276c14d5dcf731ccd5e" }
  let(:sha1){ "99c3df83b51532e3615f851d8c2dbb638f5313bf" }
  let(:sha2){ "7ed8a133d2804385eba5d3d3704f549a4d210b83" }
  let(:prod1){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "Godep1",
      name: "Godep1",
      prod_type: Project::A_TYPE_GODEP,
      language: Product::A_LANGUAGE_GO,
      version: "2.0"
    )
  }

  let(:dep1){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_GO,
      prod_key: 'Godep1',
      name: 'Godep1',
      project: project1,
      version_current: prod1[:version],
      version_requested: sha1,
      outdated: nil # important: otherwise outdated? shortcuts as last_update_ago is too small
    )
  }

  let(:dep_tag){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_GO,
      prod_key: 'Godep1',
      project: project1,
      name: 'Godep1',
      version_current: prod1[:version],
      version_requested: 'rc1',
      outdated: nil
    )
  }

  let(:dep_ver){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_GO,
      prod_key: 'Godep1',
      name: 'Godep1',
      project: project1,
      version_current: prod1[:version],
      version_requested: 'v1.7',
      outdated: nil
    )
  }
  let(:dep_cur){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_GO,
      prod_key: 'Godep1',
      name: 'Godep1',
      project: project1,
      version_current: prod1[:version],
      version_requested: '2.1',
      outdated: nil
    )
  }

  describe 'godep_to_semver' do
    it "recognizes sha codes" do
      expect(ProjectdependencyService.sha?("4b6ea7319e214d98c938f12692336f7ca9348d6b")).to be_truthy
      expect(ProjectdependencyService.sha?("3ac7bf7a47d159a033b107610db8a1b6575507a4")).to be_truthy
      expect(ProjectdependencyService.sha?("3a4c")).to be_falsey
      expect(ProjectdependencyService.sha?("")).to be_falsey
    end

    it "returns correct semver by its sha code" do
      prod1.versions << FactoryGirl.build(:product_version, version: '1.5', sha1: sha1)
      prod1.versions << FactoryGirl.build(:product_version, version: '2.0', sha1: sha_head)


      expect(ProjectdependencyService.godep_to_semver(dep1)).to eq('1.5')
    end

    it "returns an correct semver by it version tag" do
      prod1.versions << FactoryGirl.build(:product_version, version: '1.6', tag: 'rc1')
      prod1.versions << FactoryGirl.build(:product_version, version: '2.0', tag: 'rc2')


      expect(ProjectdependencyService.godep_to_semver(dep_tag)).to eq('1.6')
    end

    it "returns an correct semver by its semverable label" do
      prod1.versions << FactoryGirl.build(:product_version, version: '1.7', tag: 'v1.7')
      prod1.versions << FactoryGirl.build(:product_version, version: '2.0', tag: 'v2.0')

      expect(ProjectdependencyService.godep_to_semver(dep_ver)).to eq('1.7')
    end
  end

  describe 'outdated? for godeps packages' do
    before do
      prod1.versions << FactoryGirl.build(:product_version, version: '1.5', sha1: sha1)
      prod1.versions << FactoryGirl.build(:product_version, version: '1.6', tag: 'rc3')
      prod1.versions << FactoryGirl.build(:product_version, version: '1.7', tag: 'v1.7')
      prod1.versions << FactoryGirl.build(:product_version, version: '2.0', sha1: sha_head)
    end

    after do
      prod1.delete
    end

    it "returns true for all outdated packages" do
      expect(ProjectdependencyService.outdated?(dep1)).to be_truthy
      expect(ProjectdependencyService.outdated?(dep_tag)).to be_truthy
      expect(ProjectdependencyService.outdated?(dep_ver)).to be_truthy
    end

    it "returns false when it's matching with current version " do
      prod1.versions << FactoryGirl.build(:product_version, version: '2.1', tag: 'v2.1')

      expect(ProjectdependencyService.outdated?(dep_cur)).to be_falsey
    end

  end
end

