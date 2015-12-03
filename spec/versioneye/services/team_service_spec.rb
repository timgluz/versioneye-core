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


  describe "assign" do
    it 'doesnt assign because orga doesnt exist' do
      expect{ TeamService.assign 'asga888', 'na', ['85'], nil }.to raise_error("Organisation `asga888` doesn't exist")
    end

    it 'raises an error because user is not owner of the orga' do
      user = UserFactory.create_new
      expect( user.save ).to be_truthy

      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      expect{ TeamService.assign orga.ids, 'na', ['85'], user }.to raise_error("You have to be in the Owners team to do mass assignment.")
    end

    it 'raises an error because team does not exist inside of the orga' do
      user = UserFactory.create_new
      orga = OrganisationService.create_new user, 'my_orga'
      expect{ TeamService.assign orga.ids, 'na', ['85'], user }.to raise_error("Team `na` doesn't exist inside of the #{orga.name} organisation.")
    end

    it 'will do the mass assignment' do
      user     = UserFactory.create_new
      orga     = OrganisationService.create_new user, 'my_orga'

      project1 = ProjectFactory.create_new user
      project1.organisation_id = orga.ids
      expect( project1.save ).to be_truthy
      expect( project1.teams ).to be_empty

      project2 = ProjectFactory.create_new user
      project2.organisation_id = orga.ids
      expect( project2.save ).to be_truthy
      expect( project2.teams ).to be_empty

      expect( TeamService.assign orga.ids, 'Owners', [project2.ids, project1.ids], user ).to be_truthy
      project1.reload
      project2.reload
      expect( project1.teams.count ).to eq(1)
      expect( project2.teams.count ).to eq(1)
    end
  end


end
