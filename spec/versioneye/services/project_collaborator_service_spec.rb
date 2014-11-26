require 'spec_helper'

describe ProjectCollaboratorService do

  let( :product ) { Product.new }


  describe 'add_new' do

    it 'adds an existing user to the project' do
      ActionMailer::Base.deliveries.clear

      invitee = UserFactory.create_new 1 
      owner = UserFactory.create_new 2 

      project = ProjectFactory.create_new owner

      ProjectCollaborator.count.should eq(0)

      nc = ProjectCollaboratorService.add_new project, owner, invitee.username 
      nc.should_not be_nil 
      ProjectCollaborator.count.should eq(1)
      project.collaborators.count.should eq(1)
      pc = ProjectCollaborator.first
      pc.user_id.should eq(invitee.id.to_s)
      pc.active.should be_truthy
      pc.invitation_email.should be_nil 
      pc.invitation_code.should be_nil

      ActionMailer::Base.deliveries.size.should == 1
    end

    it 'adds an existing user to the project by email' do
      ActionMailer::Base.deliveries.clear

      invitee = UserFactory.create_new 1 
      owner = UserFactory.create_new 2 

      project = ProjectFactory.create_new owner

      ProjectCollaborator.count.should eq(0)

      nc = ProjectCollaboratorService.add_new project, owner, invitee.email 
      nc.should_not be_nil 
      ProjectCollaborator.count.should eq(1)
      project.collaborators.count.should eq(1)
      pc = ProjectCollaborator.first
      pc.user_id.should eq(invitee.id.to_s)
      pc.active.should be_truthy
      pc.invitation_email.should be_nil 
      pc.invitation_code.should be_nil

      ActionMailer::Base.deliveries.size.should == 1
    end

    it 'adds an non existing user to the project' do
      ActionMailer::Base.deliveries.clear

      owner = UserFactory.create_new 1
      project = ProjectFactory.create_new owner

      ProjectCollaborator.count.should eq(0)

      nc = ProjectCollaboratorService.add_new project, owner, 'robert@versioneye.com'
      nc.should_not be_nil 
      ProjectCollaborator.count.should eq(1)
      project.collaborators.count.should eq(1)
      pc = ProjectCollaborator.first
      pc.user_id.should be_nil 
      pc.active.should be_falsey
      pc.invitation_email.should eq('robert@versioneye.com')
      pc.invitation_code.should_not be_nil

      ActionMailer::Base.deliveries.size.should == 1
    end

  end


end
