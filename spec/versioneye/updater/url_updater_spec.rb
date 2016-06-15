require 'spec_helper'

describe UrlUpdater do

  describe 'update' do

    it 'returns the updated project' do
      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.s3_filename = 'pom.xml'
      project.url = 'https://raw.githubusercontent.com/versioneye/versioneye_maven_plugin/master/pom.xml'

      VCR.use_cassette('UrlUpdater_update', allow_playback_repeats: true) do
        described_class.new.update project
        project.should_not be_nil
        project.dependencies.count.should == 15
      end
    end


    it 'does not return the updated project because the URL does not exist.' do
      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.s3_filename = 'pom.xml'
      project.url = 'https://raw.githubusercontent.com/versioneye/versioneye_maven_plugin/masterio/pom.xml'
      expect( project.save ).to be_truthy
      expect( project.parsing_errors.count ).to eq(0)

      described_class.new.update project
      project.reload
      expect( project.parsing_errors.count ).to eq(1)
    end


  end

end
