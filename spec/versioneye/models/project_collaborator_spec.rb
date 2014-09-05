require 'spec_helper'

describe ProjectCollaborator do

  describe "collaborator?" do

    it "returns the right values" do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :caller_id => owner._id )
      collaborator.save
      project.collaborators << collaborator

      ProjectCollaborator.collaborator?(project.id, user.id).should be_falsey
      collaborator.user_id = user.id.to_s
      collaborator.save
      ProjectCollaborator.collaborator?(project.id, user.id).should be_truthy
    end

  end

  describe 'find_by_id' do
    it 'returns the right object' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :caller_id => owner._id )
      collaborator.save
      project.collaborators << collaborator

      col = ProjectCollaborator.find_by_id collaborator.id
      col.should_not be_nil
    end
  end

  describe 'owner?' do
    it 'returns false' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :user_id => user._id )
      collaborator.save
      collaborator.owner?(nil).should be_falsey
    end
    it 'returns false' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :user_id => user._id )
      collaborator.save
      collaborator.owner?(user).should be_falsey
    end
    it 'returns true' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :user_id => user._id )
      collaborator.save
      collaborator.owner?(owner).should be_truthy
    end
  end

  describe 'current?' do
    it 'returns false' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :user_id => user._id )
      collaborator.save
      collaborator.current?(nil).should be_falsey
    end
    it 'returns false' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :user_id => user._id )
      collaborator.save
      collaborator.current?(owner).should be_falsey
    end
    it 'returns true' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :user_id => user._id )
      collaborator.save
      collaborator.current?(user).should be_truthy
    end
  end

  describe 'user' do
    it 'returns the user' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :user_id => user._id )
      collaborator.save
      collaborator.user.should_not be_nil
      collaborator.user.id.to_s.should eq(user.id.to_s)
    end
  end

  describe 'owner' do
    it 'returns the owner' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :user_id => user._id )
      collaborator.save
      collaborator.owner.should_not be_nil
      collaborator.owner.id.to_s.should eq(owner.id.to_s)
    end
  end

  describe 'caller' do
    it 'returns the caller' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :caller_id => user._id )
      collaborator.save
      collaborator.caller.should_not be_nil
      collaborator.caller.id.to_s.should eq(user.id.to_s)
    end
  end

  describe 'accepted' do
    it 'returns false' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :caller_id => user._id )
      collaborator.save
      collaborator.accepted?(nil).should be_falsey
    end
    it 'returns true' do
      owner   = UserFactory.create_new 1023
      user    = UserFactory.create_new 1024
      project = ProjectFactory.create_new owner
      collaborator = ProjectCollaborator.new(:project_id => project._id,
                                             :owner_id => owner._id,
                                             :user_id => user._id,
                                             :active => true)
      collaborator.save
      collaborator.accepted?(user).should be_truthy
      collaborator.not_accepted?(user).should be_falsey
    end
  end

end
