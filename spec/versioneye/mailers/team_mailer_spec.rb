require 'spec_helper'

describe TeamMailer do

  describe 'add_new_member' do

    it 'sends out a team email' do
      user  = UserFactory.create_new 1
      owner = UserFactory.create_new 2

      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      team = Team.new({:name => 'owner', :organisation_id => orga.ids })
      expect( team.save ).to be_truthy
      expect( team.add_member(owner) ).to be_truthy


      email = TeamMailer.add_new_member(orga, team, user, owner)

      email.to.should eq( [user.email] )
      email.encoded.should include( "added you as collaborator to the team" )

      ActionMailer::Base.deliveries.clear
      email.deliver_now!
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

end
