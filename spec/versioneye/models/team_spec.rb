require 'spec_helper'

describe Team do

  describe "add_member" do
    it "adds an member" do
      user = UserFactory.create_new
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy
      team = Team.new({:name => 'owner', :organisation_id => orga.ids })
      expect(team.save).to be_truthy
      expect(team.add_member(user)).to be_truthy
      expect(Team.first.members.count).to eq(1)

      # false because already member
      expect(team.add_member(user)).to be_falsey
      expect(Team.first.members.count).to eq(1)

      # true because new member
      user2 = UserFactory.create_new 2
      expect(team.add_member(user2)).to be_truthy
      expect(Team.first.members.count).to eq(2)
    end
  end

  describe "remove_member" do
    it "remove an member" do
      user = UserFactory.create_new
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy
      team = Team.new({:name => 'owner', :organisation_id => orga.ids })
      expect(team.save).to be_truthy
      expect(team.add_member(user)).to be_truthy
      expect(Team.first.members.count).to eq(1)

      # Remove member
      expect(team.remove_member(user)).to be_truthy
      expect(Team.first.members.count).to eq(0)
      team.reload

      # returns false because member was already removed
      expect(team.remove_member(user)).to be_falsey
      expect(Team.first.members.count).to eq(0)
    end
  end

end
