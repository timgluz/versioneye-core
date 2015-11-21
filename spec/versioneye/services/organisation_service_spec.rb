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

end
