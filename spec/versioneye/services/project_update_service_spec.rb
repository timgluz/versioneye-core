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
        project.dependencies.count.should == 15
      end
    end
    it 'will update the project from URL' do
      url = 'https://s3.amazonaws.com/veye_test_env/Gemfile'
      user = UserFactory.create_new
      project = ProjectImportService.import_from_url url, 'Gemfile', user
      expect( project.save ).to be_truthy
      expect( project.source ).to eq( Project::A_SOURCE_URL )
      expect( project.url ).to eq( url )
      expect( project.dependencies ).to_not be_empty

      project = described_class.update project
      expect( project ).to_not be_nil
      expect( project.source ).to eq( Project::A_SOURCE_URL )
      expect( project.url ).to eq( url )
      expect( project.dependencies ).to_not be_empty

      # project.url = 'https://www.heise.dem/Gemfile'
      # expect( project.save ).to be_truthy
      # project = described_class.update project
      # expect( project ).to_not be_nil
      # expect( project.source ).to eq( Project::A_SOURCE_URL )
      # expect( project.url ).to eq( 'https://www.heise.dem/Gemfile' )
      # expect( project.dependencies ).to_not be_empty
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
