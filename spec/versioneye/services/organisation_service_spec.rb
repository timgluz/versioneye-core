require 'spec_helper'

describe OrganisationService do

  describe "create_new" do

    it "creates a new organisation" do
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      orga = Organisation.first
      expect( orga ).to_not be_nil
      expect( orga.name ).to eq('myorga')
      expect( orga.teams.count ).to eq(1)
      expect( orga.teams.first.name ).to eq(Team::A_OWNERS)
      expect( orga.teams.first.members.count ).to eq(1)
      expect( orga.teams.first.members.first.user.fullname ).to eq('HansTanz')
      expect( orga.teams.first.members.first.user.ids ).to eq(user.ids)
    end

    it "throws an exception because name exist already" do
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil
      expect{ OrganisationService.create_new(user, "myorga") }.to raise_exception
    end

  end


  describe "owner?" do

    it "returns true because owner" do
      user2 = UserFactory.create_new 2
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      expect( OrganisationService.owner?(orga, user) ).to be_truthy
      expect( OrganisationService.owner?(orga, user2) ).to be_falsey
    end

  end


  describe "member?" do

    it "returns true because owner" do
      user2 = UserFactory.create_new 2
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      expect( OrganisationService.member?(orga, user) ).to be_truthy
      expect( OrganisationService.member?(orga, user2) ).to be_falsey
    end

  end


  describe "allowed_to_transfer_projects?" do

    it "returns true because user is owner of orga" do
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      expect( OrganisationService.allowed_to_transfer_projects?(orga, user) ).to be_truthy
    end

    it "returns false because user2 is not member of orga" do
      user2 = UserFactory.create_new 2
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      expect( OrganisationService.allowed_to_transfer_projects?(orga, user2) ).to be_falsey
    end

    it "returns false because user2 is member of orga, but not in the owners team" do
      user2 = UserFactory.create_new 2
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil
      team = Team.new({ :name => 'team_backend' })
      team.organisation_id = orga.ids
      expect( team.save )
      expect( team.add_member(user2) )

      expect( OrganisationService.allowed_to_transfer_projects?(orga, user2) ).to be_falsey
    end

    it "returns true because user2 and orga.mattp is true" do
      user2 = UserFactory.create_new 2
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil
      orga.mattp = true
      expect( orga.save ).to be_truthy
      team = Team.new({ :name => 'team_backend' })
      team.organisation_id = orga.ids
      expect( team.save )
      expect( team.add_member(user2) )

      expect( OrganisationService.allowed_to_transfer_projects?(orga, user2) ).to be_truthy
    end

  end


  describe "allowed_to_assign_teams?" do

    it "returns true because user is owner of orga" do
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      expect( OrganisationService.allowed_to_assign_teams?(orga, user) ).to be_truthy
    end

    it "returns false because user2 is not member of orga" do
      user2 = UserFactory.create_new 2
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      expect( OrganisationService.allowed_to_assign_teams?(orga, user2) ).to be_falsey
    end

    it "returns false because user2 is member of orga, but not in the owners team" do
      user2 = UserFactory.create_new 2
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil
      team = Team.new({ :name => 'team_backend' })
      team.organisation_id = orga.ids
      expect( team.save )
      expect( team.add_member(user2) )

      expect( OrganisationService.allowed_to_assign_teams?(orga, user2) ).to be_falsey
    end

    it "returns true because user2 and orga.matattp is true" do
      user2 = UserFactory.create_new 2
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil
      orga.matattp = true
      expect( orga.save ).to be_truthy
      team = Team.new({ :name => 'team_backend' })
      team.organisation_id = orga.ids
      expect( team.save )
      expect( team.add_member(user2) )

      expect( OrganisationService.allowed_to_assign_teams?(orga, user2) ).to be_truthy
    end

  end


  describe "index" do

    it "returns a uniq. list of orgas" do
      user = UserFactory.create_new
      expect( user.save ).to be_truthy

      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      orga = OrganisationService.create_new user, "yourOrga"
      expect( orga ).to_not be_nil

      orgas = OrganisationService.index user
      expect( orgas ).to_not be_nil
      expect( orgas.count ).to eq(2)
    end

  end


  describe "orgas_allowed_to_transfer" do

    it "returns a uniq. list of orgas where the user can transfer projects to." do
      user = UserFactory.create_new
      expect( user.save ).to be_truthy
      member = UserFactory.create_new 2

      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      team = Team.new({ :name => 'team_backend' })
      team.organisation_id = orga.ids
      expect( team.save )
      expect( team.add_member(member) )

      orgas = OrganisationService.orgas_allowed_to_transfer member
      expect( orgas ).to_not be_nil
      expect( orgas.count ).to eq(0)
    end

    it "returns a uniq. list of orgas where the user can transfer projects to." do
      user = UserFactory.create_new
      expect( user.save ).to be_truthy
      member = UserFactory.create_new 2

      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil
      orga.mattp = true
      orga.save

      team = Team.new({ :name => 'team_backend' })
      team.organisation_id = orga.ids
      expect( team.save )
      expect( team.add_member(member) )

      orgas = OrganisationService.orgas_allowed_to_transfer member
      expect( orgas ).to_not be_nil
      expect( orgas.count ).to eq(1)

      orga.mattp = false
      orga.save

      orgas = OrganisationService.orgas_allowed_to_transfer member
      expect( orgas ).to_not be_nil
      expect( orgas.count ).to eq(0)
    end

    it "returns a uniq. list of orgas where the user can transfer projects to." do
      user = UserFactory.create_new
      expect( user.save ).to be_truthy

      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      orgas = OrganisationService.orgas_allowed_to_transfer user
      expect( orgas ).to_not be_nil
      expect( orgas.count ).to eq(1)
    end

  end

end
