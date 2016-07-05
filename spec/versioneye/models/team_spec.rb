require 'spec_helper'

describe Team do

  describe "to_s" do
    it "returns the name" do
      team = Team.new({:name => 'owner' })
      expect(team.to_s).to eq('owner')
    end
  end

  describe "to_param" do
    it "returns the name" do
      team = Team.new({:name => 'owner' })
      expect(team.to_param).to eq('owner')
    end
  end

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

  describe "is_member?" do
    it "is_member" do
      user = UserFactory.create_new
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy
      team = Team.new({:name => 'owner', :organisation_id => orga.ids })
      expect(team.save).to be_truthy
      expect(team.add_member(user)).to be_truthy
      expect(Team.first.members.count).to eq(1)
      expect(team.is_member?(user)).to be_truthy
    end
    it "is not a member" do
      user = UserFactory.create_new
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy
      team = Team.new({:name => 'owner', :organisation_id => orga.ids })
      expect(team.save).to be_truthy
      expect(team.add_member(user)).to be_truthy
      expect(team.is_member?(nil)).to be_falsey
    end
    it "is not a member" do
      user = UserFactory.create_new
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy
      team = Team.new({:name => 'owner', :organisation_id => orga.ids })
      expect(team.save).to be_truthy
      expect(team.add_member(user)).to be_truthy
      expect(team.is_member?( UserFactory.create_new )).to be_falsey
    end
  end

end
