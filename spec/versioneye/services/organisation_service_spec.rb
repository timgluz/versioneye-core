require 'spec_helper'

describe OrganisationService do

  describe "new" do

    it "creates a new organisation" do
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      orga = OrganisationService.create_new user, "myOrga"
      expect( orga ).to_not be_nil

      orga = Organisation.first
      expect( orga ).to_not be_nil
      expect( orga.name ).to eq('myOrga')
      expect( orga.teams.count ).to eq(1)
      expect( orga.teams.first.name ).to eq(Team::A_OWNERS)
      expect( orga.teams.first.members.count ).to eq(1)
      expect( orga.teams.first.members.first.user.fullname ).to eq('HansTanz')
      expect( orga.teams.first.members.first.user.ids ).to eq(user.ids)
    end

  end

end
