require 'spec_helper'

describe TeamService do

  describe "delete" do

    it "delete a team" do
      user = UserFactory.create_new

      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      team = Team.new({:name => 'owner', :organisation_id => orga.ids })
      expect( team.save ).to be_truthy
      expect( team.add_member(user) ).to be_truthy
      expect( TeamMember.count ).to eq(1)
      expect( TeamService.delete(team) ).to be_truthy
      expect( TeamMember.count ).to eq(0)
      expect( Team.count ).to eq(0)
    end

  end

  describe "add" do
    it 'should add 1 new team member and send out 1 email' do
      user  = UserFactory.create_new 1
      owner = UserFactory.create_new 2

      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      team = Team.new({:name => 'owner', :organisation_id => orga.ids })
      expect( team.save ).to be_truthy
      expect( team.add_member(owner) ).to be_truthy

      ActionMailer::Base.deliveries.clear
      TeamService.add team.name, orga.ids, user.username, owner

      expect( Team.where( :organisation_id => orga.ids, :name => 'owner' ).first.members.count ).to eq(2)
    end
  end

end
