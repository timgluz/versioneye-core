require 'spec_helper'

describe ProjectImportService do

  let(:github_user) { FactoryGirl.create(:github_user)}

  let(:user_with_token){create(:bitbucket_user,
      :bitbucket_token => 'YsR6vM5qxmfZtkYt9G',
      :bitbucket_secret => 'raEFhqE2YuBZtwqswGXFRZEzLnnLD8Lu',
      :bitbucket_login => Settings.instance.bitbucket_username)}


  describe 'allowed_to_add?' do
    it 'allows to add' do
      Plan.create_defaults
      user = UserFactory.create_new 1
      plan = Plan.free_plan
      user.plan = plan
      expect( user.save ).to be_truthy
      expect( described_class.allowed_to_add?(user, nil, true) ).to be_truthy
    end
    it 'does not allow to add for user' do
      Plan.create_defaults
      user = UserFactory.create_new 1
      user.plan = Plan.free_plan
      expect( user.save ).to be_truthy

      project = ProjectFactory.create_new user
      project.private_project = true
      expect( project.save ).to be_truthy
      expect( described_class.allowed_to_add?(user, nil, true) ).to be_falsey
    end
    it 'allows to add for orga' do
      Plan.create_defaults
      user = UserFactory.create_new 1
      orga = Organisation.new :name => 'test_org'
      orga.plan = Plan.free_plan
      expect( orga.save ).to be_truthy
      expect( described_class.allowed_to_add?(nil, orga, true) ).to be_truthy
    end
    it 'does not allow to add for orga' do
      Plan.create_defaults
      user = UserFactory.create_new 1
      orga = Organisation.new :name => 'test_org'
      orga.plan = Plan.free_plan
      expect( orga.save ).to be_truthy

      project = ProjectFactory.create_new user
      project.organisation_id = orga.ids
      project.private_project = true
      expect( project.save ).to be_truthy
      expect( described_class.allowed_to_add?(nil, orga, true) ).to be_falsey
    end
  end


  describe 'import_from_github' do
    it 'imports from github' do
      VCR.use_cassette('import_from_github', allow_playback_repeats: true) do
        project = ProjectImportService.import_from_github github_user, 'versioneye/versioneye_maven_plugin', 'pom.xml', 'master'
        project.should_not be_nil
        project.dependencies.should_not be_empty
        project.name.should eq('versioneye/versioneye_maven_plugin')
        project.source.should eq(Project::A_SOURCE_GITHUB)
      end
    end
    it 'imports from privat github' do
      github_user.github_id = "652130"
      github_user.github_token = '666666666666777777777777777'
      github_user.free_private_projects = 1
      github_user.save
      VCR.use_cassette('import_from_privat_github_allowed', allow_playback_repeats: true) do
        project = ProjectImportService.import_from_github github_user, 'versioneye/versioneye-core', 'Gemfile', 'master'
        project.should_not be_nil
        project.dependencies.should_not be_empty
        project.name.should eq('versioneye/versioneye-core')
        project.source.should eq(Project::A_SOURCE_GITHUB)
      end
    end
    it 'imports not from privat github, because plan to low' do
      github_user.github_id = "652130"
      github_user.github_token = '666666666666777777777777777'
      github_user.free_private_projects = 0
      github_user.save
      VCR.use_cassette('import_from_privat_github_not_allowed', allow_playback_repeats: true) do
        expect { ProjectImportService.import_from_github(github_user, 'versioneye/versioneye-core', 'Gemfile', 'master') }.to raise_error
      end
    end
    it 'does not import from github because file does not exist' do
      expect { ProjectImportService.import_from_github github_user, 'versioneye/versioneye_maven_plugin', 'pomi.xml', 'master' }.to raise_error
    end
  end


  describe 'import_from_github_async' do
    it 'imports from github async' do
      worker = Thread.new{ GitRepoFileImportWorker.new.work }
      github_user.github_id = 652130
      github_user.save.should be_truthy
      VCR.use_cassette('import_from_github_async', allow_playback_repeats: true) do
        Project.all.count.should eq(0)
        status = ''
        until status.match(/\Adone_/)
          status = ProjectImportService.import_from_github_async github_user, 'versioneye/versioneye_maven_plugin', 'pom.xml', 'master'
          p "status: #{status}"
          sleep 2
        end
        Project.all.count.should eq(1)
      end
      worker.exit
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


  describe 'import_from_bitbucket_async' do
    it 'imports from bitbucket async' do
      bitbucket_repo = BitbucketRepo.new({:fullname => 'reiz/test_gemi', :user => user_with_token, :private => false})
      bitbucket_repo.save
      worker = Thread.new{ GitRepoFileImportWorker.new.work }
      VCR.use_cassette('import_from_bitbucket_async', allow_playback_repeats: true) do
        Project.all.count.should eq(0)
        status = ''
        until status.match(/\Adone_/)
          status = ProjectImportService.import_from_bitbucket_async user_with_token, 'reiz/test_gemi', 'pom.xml', 'master'
          sleep 2
        end
        Project.all.count.should eq(1)
      end
      worker.exit
    end
  end



  # TODO Tests for Stash !!



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
    end
  end

  describe "allowed_to_add_project?" do

    it "allows because its a public project" do
      described_class.allowed_to_add_project?(nil, false).should be_truthy
    end

    it "allows because each user has 1 private project for free" do
      Plan.create_defaults
      described_class.allowed_to_add_project?(github_user, nil, true).should be_truthy
    end

    it "allows because user has a plan and no projects" do
      Plan.create_defaults
      plan = Plan.by_name_id( Plan::A_PLAN_SMALL )
      user = github_user
      user.plan = plan
      user.save
      described_class.allowed_to_add_project?(github_user, nil, true).should be_truthy
    end

    it "denies because user has a plan and to many private projects already" do
      Plan.create_defaults
      plan = Plan.by_name_id( Plan::A_PLAN_SMALL )
      user = github_user
      user.plan = plan
      user.save
      plan.private_projects.times { ProjectFactory.create_new( user, {:private_project => true} ) }
      described_class.allowed_to_add_project?(github_user, nil, true).should be_falsey
    end

    it "allows because user has a plan and to many private projects already, but 1 additional free project" do
      Plan.create_defaults
      plan = Plan.by_name_id( Plan::A_PLAN_SMALL )
      user = github_user
      user.plan = plan
      user.free_private_projects = 1
      user.save
      plan.private_projects.times { ProjectFactory.create_new( user, {:private_project => true} ) }
      described_class.allowed_to_add_project?(github_user, nil, true).should be_truthy
    end

    it "denises because user has a plan and to many private projects already" do
      Plan.create_defaults
      plan = Plan.by_name_id( Plan::A_PLAN_SMALL )
      user = github_user
      user.plan = plan
      user.free_private_projects = 1
      user.save
      max = plan.private_projects + user.free_private_projects
      max.times { ProjectFactory.create_new( user, {:private_project => true} ) }
      described_class.allowed_to_add_project?(github_user, nil, true).should be_falsey
    end

    it "is not allowed in Enterprise" do
      Settings.instance.instance_variable_set(:@environment, 'enterprise')
      user = github_user
      GlobalSetting.set 'enterprise', 'E_PROJECTS', '0'
      ProjectImportService.allowed_to_add_project?( user, nil, true ).should be_falsey
      Settings.instance.instance_variable_set(:@environment, 'test')
    end

    it "is not allowed in Enterprise" do
      Settings.instance.instance_variable_set(:@environment, 'enterprise')
      user = github_user
      GlobalSetting.set 'enterprise', 'E_PROJECTS', '1'
      ProjectImportService.allowed_to_add_project?( user, nil, true ).should be_truthy
      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end

end
