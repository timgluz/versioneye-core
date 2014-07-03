require 'spec_helper'

describe ProjectUpdateService do

  describe 'update' do

    it 'will update the project' do
      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.s3_filename = 'pom.xml'
      project.scm_fullname = 'versioneye/versioneye_maven_plugin'
      project.scm_branch = 'master'
      project.source = Project::A_SOURCE_GITHUB

      VCR.use_cassette('ProjectUpdateService_update', allow_playback_repeats: true) do
        project = described_class.update project
        project.should_not be_nil
        project.dependencies.count.should == 11
      end

    end

  end

  describe 'update_collaborators_projects' do

    it 'will remove the collaborator because project is nil' do
      pc = ProjectCollaborator.new({:project_id => "87", :owner_id => "2", :user_id => "1", :caller_id => "2"})
      pc.active = true
      pc.period = Project::A_PERIOD_WEEKLY
      pc.save.should be_truthy

      ProjectCollaborator.count.should == 1

      VCR.use_cassette('ProjectUpdateService_update_collaborators_projects', allow_playback_repeats: true) do
        described_class.update_collaborators_projects Project::A_PERIOD_WEEKLY
      end

      ProjectCollaborator.count.should == 0
    end

  end

  describe 'update_all' do

    it 'will update all and send 0 emails because everything is up-to-date' do
      ActionMailer::Base.deliveries.clear

      user = UserFactory.create_new
      hans = UserFactory.create_new 2

      project = ProjectFactory.default user
      project.s3_filename = 'pom.xml'
      project.scm_fullname = 'versioneye/versioneye_maven_plugin'
      project.scm_branch = 'master'
      project.source = Project::A_SOURCE_GITHUB
      project.period = Project::A_PERIOD_WEEKLY
      project.dependencies.count.should == 3
      project.save

      pc = ProjectCollaborator.new({:project_id => project.id.to_s, :owner_id => user.id.to_s, :user_id => hans.id.to_s, :caller_id => user.id.to_s})
      pc.active = true
      pc.period = Project::A_PERIOD_WEEKLY
      pc.save.should be_truthy

      VCR.use_cassette('ProjectUpdateService_update_all', allow_playback_repeats: true) do
        described_class.update_all Project::A_PERIOD_WEEKLY
        project.reload
        project.dependencies.count.should == 11
      end

      ActionMailer::Base.deliveries.size.should == 0
    end

    it 'will update all and send 2 emails because it is not up-to-date' do
      ActionMailer::Base.deliveries.clear

      product = ProductFactory.create_for_maven 'org.apache.maven', 'maven-compat', '10.0.0'
      product.save.should be_truthy

      user = UserFactory.create_new
      hans = UserFactory.create_new 2

      project = ProjectFactory.default user
      project.s3_filename = 'pom.xml'
      project.scm_fullname = 'versioneye/versioneye_maven_plugin'
      project.scm_branch = 'master'
      project.source = Project::A_SOURCE_GITHUB
      project.period = Project::A_PERIOD_WEEKLY
      project.dependencies.count.should == 3
      project.save

      pc = ProjectCollaborator.new({:project_id => project.id.to_s, :owner_id => user.id.to_s, :user_id => hans.id.to_s, :caller_id => user.id.to_s})
      pc.active = true
      pc.period = Project::A_PERIOD_WEEKLY
      pc.save.should be_truthy

      VCR.use_cassette('ProjectUpdateService_update_all_2', allow_playback_repeats: true) do
        described_class.update_all Project::A_PERIOD_WEEKLY
        project.reload
        project.dependencies.count.should == 11
      end

      ActionMailer::Base.deliveries.size.should == 2
    end

  end

  describe 'update_from_upload' do

    it 'updates an existing project from a file upload' do

      gemfile = "spec/fixtures/files/Gemfile"
      file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
      file = {'datafile' => file_attachment}

      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.s3_filename = 'Gemfile'
      project.source = Project::A_SOURCE_UPLOAD
      project.save.should be_truthy
      Project.count.should == 1

      project = described_class.update_from_upload project, file, user
      project.should_not be_nil
      project.dependencies.count.should > 0
      Project.count.should == 1
    end

  end

end
