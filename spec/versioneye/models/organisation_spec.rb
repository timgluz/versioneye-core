require 'spec_helper'

describe Organisation do

  describe "teams" do
    it 'owns a team' do
      team = Team.new({:name => 'owners'})
      expect( team.save ).to be_truthy

      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      team.organisation = orga
      expect( team.save ).to be_truthy

      orga = Organisation.first
      expect( orga.teams.count ).to eq(1)
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
