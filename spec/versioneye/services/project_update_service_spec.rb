require 'spec_helper'

describe ProjectUpdateService do

  describe 'status_for' do
    it 'returns done for not existing project' do
      expect( described_class.status_for 'sfafgas-NAN---' ).to eq('done')
    end
  end

  describe 'update_async' do
    it 'updates async and returns the right status code' do
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

      expect( described_class.update_async project ).to eql('running')
      expect( described_class.update_async project ).to eql('running')
      expect( described_class.status_for project.ids ).to eq('running')

      worker = Thread.new{ ProjectUpdateWorker.new.work }
      sleep 2
      expect( described_class.status_for project.ids ).to eq('done')
      worker.exit
    end
  end

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
    it 'will update a multi file project' do
      user = UserFactory.create_new
      gemfile = import_gemfile user
      expect( gemfile ).to_not be_nil

      podfile = import_podfile user
      expect( podfile ).to_not be_nil

      podfile.parent_id = gemfile.ids
      expect( podfile.save ).to be_truthy

      rails = ProductFactory.create_for_gemfile 'rails', '3.2.6'
      rails.save

      jsonkit = ProductFactory.create_for_cocoapods 'jsonkit', '1.1.0'
      jsonkit.save

      add_sv jsonkit

      gemfile = described_class.update gemfile
      expect( gemfile ).to_not be_nil
      expect( gemfile.sv_count ).to eq(0)
      expect( gemfile.sv_count_sum ).to eq(1)

      podfile.reload
      expect( podfile.sv_count ).to eq(1)
      expect( podfile.sv_count_sum ).to eq(1)

      add_sv rails

      gemfile = described_class.update gemfile
      expect( gemfile ).to_not be_nil
      expect( gemfile.sv_count ).to eq(1)
      expect( gemfile.sv_count_sum ).to eq(2)
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

    it 'updates an existing project from a file upload and updates the sums for parent' do
      gemfile = "spec/fixtures/files/Gemfile"
      file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
      file = {'datafile' => file_attachment}

      user    = UserFactory.create_new

      parent = ProjectFactory.create_new user
      parent.name = 'parent'
      parent.s3_filename = 'Gemfile'
      parent.source = Project::A_SOURCE_UPLOAD
      parent.save.should be_truthy
      parent.dependencies.count.should eq(0)
      parent.dep_number_sum.should eq(0)
      Project.count.should == 1

      project = ProjectFactory.create_new user
      project.name = 'child'
      project.s3_filename = 'Gemfile'
      project.source = Project::A_SOURCE_UPLOAD
      project.parent_id = parent.ids
      project.save.should be_truthy
      Project.count.should == 2

      project = described_class.update_from_upload project, file, user
      project.should_not be_nil
      project.reload
      project.dependencies.size.should > 0
      project.dep_number.should > 0
      project.dep_number_sum.should > 0
      Project.count.should == 2

      parent.reload
      parent.dep_number.should eq(0)
      parent.dep_number_sum.should > 0
    end
  end


  def import_gemfile user
    gemfile = "spec/fixtures/files/Gemfile"
    file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
    file = {'datafile' => file_attachment}
    ProjectImportService.import_from_upload file, user
  end

  def import_podfile user
    gemfile = "spec/fixtures/files/pod_file/example1/Podfile"
    file_attachment = Rack::Test::UploadedFile.new(gemfile, "application/octet-stream")
    file = {'datafile' => file_attachment}
    ProjectImportService.import_from_upload file, user
  end

  def add_sv product
    sv = SecurityVulnerability.new({:language => product.language, :prod_key => product.prod_key, :summary => 'test'})
    sv.affected_versions << product.version
    sv.save
    version = product.version_by_number product.version
    version.sv_ids << sv.ids
    version.save
  end

end
