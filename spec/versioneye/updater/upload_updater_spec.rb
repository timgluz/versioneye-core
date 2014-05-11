require 'spec_helper'

describe UploadUpdater do

  describe 'update' do

    it 'returns the updated project' do
      user = UserFactory.create_new
      project = ProjectFactory.default user

      described_class.new.update project
      project.should_not be_nil
      project.dependencies.count.should == 3
      ProjectService.outdated_dependencies( project ).count.should == 2
    end

  end

end
