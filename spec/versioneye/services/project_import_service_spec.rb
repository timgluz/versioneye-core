require 'spec_helper'

describe ProjectImportService do

  let(:github_user) { FactoryGirl.create(:github_user)}

  let(:user_with_token){create(:bitbucket_user,
      :bitbucket_token => 'YsR6vM5qxmfZtkYt9G',
      :bitbucket_secret => 'raEFhqE2YuBZtwqswGXFRZEzLnnLD8Lu',
      :bitbucket_login => Settings.instance.bitbucket_username)}


  before(:each) do
    Plan.create_defaults
  end

  describe 'allowed_to_add?' do
    it 'allows to add for orga' do
      Plan.create_defaults
      user = UserFactory.create_new 1
      orga = Organisation.new :name => 'test_org'
      orga.plan = Plan.free_plan
      expect( orga.save ).to be_truthy
      expect( described_class.allowed_to_add?(orga, true) ).to be_truthy
    end
    it 'does not allow to add for orga' do
      Plan.create_defaults
      user = UserFactory.create_new 1
      orga = Organisation.new :name => 'test_org'
      orga.plan = Plan.free_plan
      expect( orga.save ).to be_truthy

      project = ProjectFactory.create_new user, nil, true, orga
      project.private_project = true
      expect( project.save ).to be_truthy

      project = ProjectFactory.create_new user, nil, true, orga
      project.private_project = true
      expect( project.save ).to be_truthy

      expect( described_class.allowed_to_add?(orga, true) ).to be_falsey
    end
  end


  describe 'import_from_github' do
    it 'imports from github' do
      VCR.use_cassette('import_from_github', allow_playback_repeats: true) do
        orga = OrganisationService.create_new github_user, "test_orga"
        orga.plan = Plan.micro
        expect( orga.save ).to be_truthy
        project = ProjectImportService.import_from_github github_user, 'versioneye/versioneye_maven_plugin', 'pom.xml', 'master', orga.ids
        expect( project ).to_not be_nil
        expect( project.dependencies ).to_not be_empty
        expect( project.name ).to eq('versioneye/versioneye_maven_plugin')
        expect( project.source ).to eq(Project::A_SOURCE_GITHUB)
      end
    end
    it 'imports from privat github' do
      github_user.github_id = "652130"
      github_user.github_token = '666666666666777777777777777'
      github_user.save
      orga = OrganisationService.create_new github_user, "test_orga"
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy
      VCR.use_cassette('import_from_privat_github_allowed', allow_playback_repeats: true) do
        project = ProjectImportService.import_from_github github_user, 'versioneye/versioneye-core', 'Gemfile', 'master', orga.ids
        expect( project ).to_not be_nil
        expect( project.dependencies ).to_not be_empty
        expect( project.name ).to eq('versioneye/versioneye-core')
        expect( project.source ).to eq(Project::A_SOURCE_GITHUB)
      end
    end
    it 'imports not from privat github, because plan to low' do
      github_user.github_id = "652130"
      github_user.github_token = '666666666666777777777777777'
      github_user.save
      orga = Organisation.new({:name => 'test', :plan => Plan.free_plan})
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy
      VCR.use_cassette('import_from_privat_github_not_allowed', allow_playback_repeats: true) do
        expect { ProjectImportService.import_from_github(github_user, 'versioneye/versioneye-core', 'Gemfile', 'master', orga.ids) }.to raise_error
      end
    end
    it 'does not import from github because file does not exist' do
      orga = Organisation.new({:name => 'test', :plan => Plan.free_plan})
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy
      expect { ProjectImportService.import_from_github github_user, 'versioneye/versioneye_maven_plugin', 'pomi.xml', 'master', orga.ids }.to raise_error
    end
  end


  describe 'import_from_github_async' do
    it 'imports from github async' do
      worker = Thread.new{ GitRepoFileImportWorker.new.work }
      github_user.github_id = 652130
      expect( github_user.save ).to be_truthy
      orga = OrganisationService.create_new_for github_user
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy
      VCR.use_cassette('import_from_github_async', allow_playback_repeats: true) do
        expect( Project.all.count ).to eq(0)
        status = ''
        until status.match(/\Adone_/)
          status = ProjectImportService.import_from_github_async github_user, 'versioneye/versioneye_maven_plugin', 'pom.xml', 'master', orga.ids
          p "status: #{status}"
          sleep 2
        end
        expect( Project.all.count ).to eq(1)
      end
      worker.exit
    end
  end


  describe 'import_from_bitbucket' do
    it 'imports from bitbucket' do
      bitbucket_repo = BitbucketRepo.new({:fullname => 'versioneye_test/fantom_hydra', :user => user_with_token, :private => false})
      bitbucket_repo.save

      VCR.use_cassette('bitbucket_file_import', allow_playback_repeats: true) do
        orga = OrganisationService.create_new_for user_with_token
        orga.plan = Plan.micro
        expect( orga.save ).to be_truthy
        project = ProjectImportService.import_from_bitbucket user_with_token, 'versioneye_test/fantom_hydra', 'Gemfile', 'master', orga.ids
        expect( project ).to_not be_nil
        expect( project.dependencies ).to_not be_empty
        expect( project.name ).to eq('versioneye_test/fantom_hydra')
        expect( project.source ).to eq(Project::A_SOURCE_BITBUCKET)
      end
    end
    it 'does not import from bitbucket because file does not exist' do
      bitbucket_repo = BitbucketRepo.new({:fullname => 'versioneye_test/fantom_hydra', :user => user_with_token, :private => false})
      bitbucket_repo.save

      orga = OrganisationService.create_new_for user_with_token
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy

      project = ProjectImportService.import_from_bitbucket user_with_token, 'versioneye_test/fantom_hydra', 'GemGemify', 'master', orga.ids
      expect( project ).to_not be_nil
      expect( project ).to match("Didn't find any project")
    end
  end


  describe 'import_from_bitbucket_async' do
    it 'imports from bitbucket async' do
      bitbucket_repo = BitbucketRepo.new({:fullname => 'reiz/test_gemi', :user => user_with_token, :private => false})
      bitbucket_repo.save
      worker = Thread.new{ GitRepoFileImportWorker.new.work }
      VCR.use_cassette('import_from_bitbucket_async', allow_playback_repeats: true) do
        orga = OrganisationService.create_new_for user_with_token
        orga.plan = Plan.micro
        expect( orga.save ).to be_truthy
        expect( Project.all.count ).to eq(0)
        status = ''
        until status.match(/\Adone_/)
          status = ProjectImportService.import_from_bitbucket_async user_with_token, 'reiz/test_gemi', 'pom.xml', 'master', orga.ids
          sleep 2
        end
        expect( Project.all.count ).to eq(1)
      end
      worker.exit
    end
  end



  # TODO Tests for Stash !!


  describe 'import_from_url' do
    it 'creates a project from url' do
      orga = OrganisationService.create_new_for github_user
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy
      url = 'https://bitbucket.org/reiz/test_gemi/raw/3691cce15b9d77934f21e372923a22465cf8ed7b/Gemfile'
      project = ProjectImportService.import_from_url url, "url_test_project", github_user
      expect( project ).to_not be_nil
      expect( project.dependencies ).to_not be_empty
      expect( project.name ).to eq('url_test_project')
      expect( project.source ).to eq(Project::A_SOURCE_URL)
      expect( project.url ).to eq( url )
    end
  end

  describe 'import_from_upload' do
    it 'imports from file upload' do
      gemfile = "spec/fixtures/files/Gemfile"
      file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
      file = {'datafile' => file_attachment}

      orga = OrganisationService.create_new_for github_user
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy

      project = ProjectImportService.import_from_upload file, github_user, false, orga.ids
      expect( project ).to_not be_nil
      expect( project.dependencies ).to_not be_empty
      expect( project.name ).to eq('Gemfile')
      expect( project.source ).to eq(Project::A_SOURCE_UPLOAD)
      expect( project.url ).to be_nil
    end
  end

  describe "allowed_to_add_project?" do

    it "allows not because orga is nil" do
      expect( described_class.allowed_to_add_project?(nil, false) ).to be_falsey
    end

    it "allows because its a public project" do
      orga = OrganisationService.create_new_for github_user
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy
      expect( described_class.allowed_to_add_project?(orga.ids, false) ).to be_truthy
    end

    it "allows because each user has 1 private project for free" do
      Plan.create_defaults
      plan = Plan.by_name_id( Plan::A_PLAN_SMALL )
      orga = Organisation.new({:name => 'test_orga'})
      orga.plan = plan
      orga.save
      expect( described_class.allowed_to_add_project?(orga, true) ).to be_truthy
    end

    it "allows because orga has a plan and no projects" do
      Plan.create_defaults
      plan = Plan.by_name_id( Plan::A_PLAN_SMALL )
      orga = Organisation.new({:name => 'test_orga'})
      orga.plan = plan
      orga.save
      expect( described_class.allowed_to_add_project?(orga, true) ).to be_truthy
    end

    it "denies because user has a plan and to many private projects already" do
      Plan.create_defaults
      plan = Plan.by_name_id( Plan::A_PLAN_SMALL )
      orga = Organisation.new({:name => 'test_orga'})
      orga.plan = plan
      orga.save
      (plan.private_projects + 1).times { ProjectFactory.create_new( github_user, {:private_project => true}, true, orga ) }
      expect( described_class.allowed_to_add_project?(orga, true) ).to be_falsey
    end

    it "denises because user has a plan and to many private projects already" do
      Plan.create_defaults
      plan = Plan.by_name_id( Plan::A_PLAN_SMALL )
      orga = Organisation.new({:name => 'test_orga'})
      orga.plan = plan
      orga.save
      max = plan.private_projects
      max += 1
      max.times { ProjectFactory.create_new( github_user, {:private_project => true}, true, orga ) }
      expect( described_class.allowed_to_add_project?(orga, true) ).to be_falsey
    end

    # This is allowed now because business model changed.
    # Now we charge for the sync of the components.
    it "is allowed in Enterprise" do
      Settings.instance.instance_variable_set(:@environment, 'enterprise')
      orga = Organisation.new({:name => 'test_orga', :plan => Plan.free_plan})
      GlobalSetting.set 'enterprise', 'E_PROJECTS', '0'
      expect( ProjectImportService.allowed_to_add_project?( nil, true ) ).to be_truthy
      Settings.instance.instance_variable_set(:@environment, 'test')
    end

    it "is not allowed in Enterprise" do
      Settings.instance.instance_variable_set(:@environment, 'enterprise')
      user = github_user
      GlobalSetting.set 'enterprise', 'E_PROJECTS', '1'
      expect( ProjectImportService.allowed_to_add_project?( nil, true ) ).to be_truthy
      Settings.instance.instance_variable_set(:@environment, 'test')
    end

  end

end
