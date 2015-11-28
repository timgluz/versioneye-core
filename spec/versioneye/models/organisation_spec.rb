require 'spec_helper'

describe Organisation do

  describe "teams" do
    it 'owns a team' do
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      team = Team.new({:name => 'owners', :organisation_id => orga })
      expect( team.save ).to be_truthy

      team.organisation = orga
      expect( team.save ).to be_truthy

      orga = Organisation.first
      expect( orga.teams.count ).to eq(1)
    end
  end


  describe "owner_team" do
    it 'returns the owner team' do
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      team = Team.new({:name => Team::A_OWNERS, :organisation_id => orga })
      expect( team.save ).to be_truthy

      team.organisation = orga
      expect( team.save ).to be_truthy

      expect( orga.owner_team.name ).to eq(Team::A_OWNERS)
    end
  end


  describe "team_by" do
    it 'returns the team by name' do
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      team = Team.new({:name => 'team1', :organisation_id => orga })
      expect( team.save ).to be_truthy

      team.organisation = orga
      expect( team.save ).to be_truthy

      expect( orga.team_by('team1').name ).to eq('team1')
      expect( orga.team_by('team') ).to be_nil
    end
  end


  describe "projects" do
    it 'owns a project' do
      user = UserFactory.create_new
      project = ProjectFactory.create_new user
      expect( project.save ).to be_truthy

      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      project.organisation = orga
      expect( project.save ).to be_truthy

      orga = Organisation.first
      expect( orga.projects.count ).to eq(1)
    end
  end

end
