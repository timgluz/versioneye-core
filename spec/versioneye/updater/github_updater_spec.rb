require 'spec_helper'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes/'
  c.ignore_localhost = true
  c.hook_into :webmock
end

describe GithubUpdater do

  describe 'update' do

    it 'returns nil' do
      user = UserFactory.create_new
      project = ProjectFactory.default user

      new_project = GithubUpdater.new.update project
      new_project.should be_nil
    end

    it 'returns the updated project' do

      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.s3_filename = 'pom.xml'
      project.scm_fullname = 'versioneye/versioneye_maven_plugin'
      project.scm_branch = 'master'

      WebMock.disable_net_connect!
      VCR.use_cassette('github_updater_pom_xml_1', allow_playback_repeats: true) do
        described_class.new.update project
        project.should_not be_nil
        project.dependencies.count.should == 15
      end
      WebMock.allow_net_connect!
    end

    it 'returns the updated project / Podfile' do
      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.s3_filename = 'Example/Podfile'
      project.scm_fullname = 'xing/XNGAPIClient'
      project.scm_branch = 'master'

      WebMock.disable_net_connect!
      VCR.use_cassette('github_updater_podfile_1', allow_playback_repeats: true) do
        described_class.new.update project
        project.should_not be_nil
        project.dependencies.count.should == 4
      end
      WebMock.allow_net_connect!
    end

  end

  describe 'fetch_project_file' do

    it 'returns new project_file fetched from GitHub' do
      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.s3_filename = 'pom.xml'
      project.scm_fullname = 'versioneye/versioneye_maven_plugin'
      project.scm_branch = 'master'

      WebMock.disable_net_connect!
      VCR.use_cassette('github_updater_pom_xml_2', allow_playback_repeats: true) do
        pf = described_class.new.fetch_project_file project
        pf.should_not be_nil
        pf[:type].should eq("Maven2")
        pf[:name].should eq("pom.xml")
        pf[:content].should_not be_nil
      end
      WebMock.allow_net_connect!
    end

  end

end
