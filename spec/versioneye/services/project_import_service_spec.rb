require 'spec_helper'

describe ProjectImportService do

  let(:github_user) { FactoryGirl.create(:github_user)}

  let(:user_with_token){create(:bitbucket_user,
      :bitbucket_token => 'YsR6vM5qxmfZtkYt9G',
      :bitbucket_secret => 'raEFhqE2YuBZtwqswGXFRZEzLnnLD8Lu',
      :bitbucket_login => Settings.instance.bitbucket_username)}


  describe 'import_from_github' do

    it 'imports from github' do
      VCR.use_cassette('import_from_github', allow_playback_repeats: true) do
        project = ProjectImportService.import_from_github github_user, 'versioneye/versioneye_maven_plugin', 'pom.xml', 'master'
        project.should_not be_nil
        project.dependencies.should_not be_empty
        project.name.should eq('versioneye/versioneye_maven_plugin')
        project.source.should eq(Project::A_SOURCE_GITHUB)
        project.api_created.should be_false
      end
    end

    it 'does not import from github because file does not exist' do
      project = ProjectImportService.import_from_github github_user, 'versioneye/versioneye_maven_plugin', 'pomi.xml', 'master'
      project.should match("Didn't find any project")
    end

  end


  describe 'import_from_bitbucket' do

    it 'imports from bitbucket' do
      bitbucket_repo = BitbucketRepo.new({:fullname => 'versioneye_test/fantom_hydra', :user => user_with_token, :private => false})
      bitbucket_repo.save

      VCR.use_cassette('bitbucket_file_import', allow_playback_repeats: true) do
        project = ProjectImportService.import_from_bitbucket user_with_token, 'versioneye_test/fantom_hydra', 'Gemfile', 'master'
        project.should_not be_nil
        project.dependencies.should_not be_empty
        project.name.should eq('versioneye_test/fantom_hydra')
        project.source.should eq(Project::A_SOURCE_BITBUCKET)
        project.api_created.should be_false
      end
    end

    it 'does not import from bitbucket because file does not exist' do
      bitbucket_repo = BitbucketRepo.new({:fullname => 'versioneye_test/fantom_hydra', :user => user_with_token, :private => false})
      bitbucket_repo.save

      project = ProjectImportService.import_from_bitbucket user_with_token, 'versioneye_test/fantom_hydra', 'GemGemify', 'master'
      project.should_not be_nil
      project.should match("Didn't find any project")
    end

  end


  describe 'import_from_url' do

    it 'creates a project from url' do
      url = 'https://bitbucket.org/reiz/test_gemi/raw/3691cce15b9d77934f21e372923a22465cf8ed7b/Gemfile'
      project = ProjectImportService.import_from_url url, "url_test_project", github_user
      project.should_not be_nil
      project.dependencies.should_not be_empty
      project.name.should eq('url_test_project')
      project.source.should eq(Project::A_SOURCE_URL)
      project.url.should eq( url )
    end

  end

  describe 'import_from_upload' do

    it 'imports from file upload' do
      gemfile = "spec/fixtures/files/Gemfile"
      file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
      file = {'datafile' => file_attachment}

      project = ProjectImportService.import_from_upload file, github_user
      project.should_not be_nil
      project.dependencies.should_not be_empty
      project.name.should eq('Gemfile')
      project.source.should eq(Project::A_SOURCE_UPLOAD)
      project.url.should be_nil
      project.api_created.should be_false
    end

  end

  describe "allowed_to_add_project?" do

    it "allows because its a public project" do
      described_class.allowed_to_add_project?(nil, false).should be_true
    end

    it "allows because each user has 1 private project for free" do
      Plan.create_default_plans
      described_class.allowed_to_add_project?(github_user, true).should be_true
    end

    it "allows because user has a plan and no projects" do
      Plan.create_default_plans
      plan = Plan.by_name_id( Plan::A_PLAN_PERSONAL_3 )
      user = github_user
      user.plan = plan
      user.save
      described_class.allowed_to_add_project?(github_user, true).should be_true
    end

    it "denies because user has a plan and to many private projects already" do
      Plan.create_default_plans
      plan = Plan.by_name_id( Plan::A_PLAN_PERSONAL_3 )
      user = github_user
      user.plan = plan
      user.save
      plan.private_projects.times { ProjectFactory.create_new( user, {:private_project => true} ) }
      described_class.allowed_to_add_project?(github_user, true).should be_false
    end

    it "allows because user has a plan and to many private projects already, but 1 additional free project" do
      Plan.create_default_plans
      plan = Plan.by_name_id( Plan::A_PLAN_PERSONAL_3 )
      user = github_user
      user.plan = plan
      user.free_private_projects = 1
      user.save
      plan.private_projects.times { ProjectFactory.create_new( user, {:private_project => true} ) }
      described_class.allowed_to_add_project?(github_user, true).should be_true
    end

    it "denises because user has a plan and to many private projects already" do
      Plan.create_default_plans
      plan = Plan.by_name_id( Plan::A_PLAN_PERSONAL_3 )
      user = github_user
      user.plan = plan
      user.free_private_projects = 1
      user.save
      max = plan.private_projects + user.free_private_projects
      max.times { ProjectFactory.create_new( user, {:private_project => true} ) }
      described_class.allowed_to_add_project?(github_user, true).should be_false
    end

    it "allows because unlimited projects is true" do
      Plan.create_default_plans
      plan = Plan.by_name_id( Plan::A_PLAN_PERSONAL_3 )
      user = github_user
      user.plan = plan
      user.free_private_projects = 1
      user.save
      max = plan.private_projects + user.free_private_projects
      max.times { ProjectFactory.create_new( user, {:private_project => true} ) }
      Settings.instance.projects_unlimited = true
      described_class.allowed_to_add_project?(github_user, true).should be_true
    end

  end

end
