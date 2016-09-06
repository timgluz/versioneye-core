require 'spec_helper'

describe Organisation do


  describe "to_param" do
    it 'returns the name' do
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.to_param ).to eq('Orga')
    end
  end


  describe "to_s" do
    it 'returns the name' do
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.to_s ).to eq('Orga')
    end
  end


  describe "default_lwl_id" do
    it 'returns nil because lwl list is empty' do
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.default_lwl_id ).to be_nil
    end
    it 'returns nil because there is no default lwl' do
      orga = Organisation.new({:name => 'Orga'})
      lwl = LicenseWhitelist.new({:name => 'lwl'})
      lwl.organisation = orga
      expect( lwl.save ).to be_truthy
      expect( orga.default_lwl_id ).to be_nil
    end
    it 'returns the default lwl' do
      orga = Organisation.new({:name => 'Orga'})
      lwl = LicenseWhitelist.new({:name => 'lwl', :default => true})
      lwl.organisation = orga
      expect( lwl.save ).to be_truthy
      expect( orga.default_lwl_id ).to eq(lwl.ids)
    end
  end


  describe "default_cwl_id" do
    it 'returns nil because lwl list is empty' do
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.default_cwl_id ).to be_nil
    end
    it 'returns nil because there is no default cwl' do
      orga = Organisation.new({:name => 'Orga'})
      cwl = ComponentWhitelist.new({:name => 'cwl'})
      cwl.organisation = orga
      expect( cwl.save ).to be_truthy
      expect( orga.default_cwl_id ).to be_nil
    end
    it 'returns the default cwl' do
      orga = Organisation.new({:name => 'Orga'})
      cwl  = ComponentWhitelist.new({:name => 'cwl', :default => true})
      cwl.organisation = orga
      expect( cwl.save ).to be_truthy
      expect( orga.default_cwl_id ).to eq(cwl.ids)
    end
  end


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


  describe "unique_languages" do
    it 'returns the uniq. languages' do
      user = UserFactory.create_new
      project = ProjectFactory.create_new user
      project.language = 'Java'
      expect( project.save ).to be_truthy

      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      project.organisation = orga
      expect( project.save ).to be_truthy

      team = Team.new({:name => 'owners', :organisation_id => orga })
      expect( team.save ).to be_truthy

      expect( orga.unique_languages ).to_not be_empty
      expect( orga.unique_languages.count ).to eq(1)
      expect( orga.unique_languages.first ).to eq('Java')
    end
    it 'returns an empty array because there are no projects' do
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      team = Team.new({:name => 'owners', :organisation_id => orga })
      expect( team.save ).to be_truthy

      expect( orga.unique_languages ).to be_empty
    end
  end


  describe "unique_versions" do
    it 'returns the uniq. languages' do
      user = UserFactory.create_new
      project = ProjectFactory.create_new user
      project.language = 'Java'
      project.version = '1.0.0'
      expect( project.save ).to be_truthy

      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      project.organisation = orga
      expect( project.save ).to be_truthy

      team = Team.new({:name => 'owners', :organisation_id => orga })
      expect( team.save ).to be_truthy

      expect( orga.unique_versions ).to_not be_empty
      expect( orga.unique_versions.count ).to eq(1)
      expect( orga.unique_versions.first ).to eq('1.0.0')
    end
    it 'returns an empty array because there are no projects' do
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      team = Team.new({:name => 'owners', :organisation_id => orga })
      expect( team.save ).to be_truthy

      expect( orga.unique_versions ).to be_empty
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


  describe "api" do
    it 'returns a new api' do
      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      api = orga.api
      expect( api ).to_not be_nil
      expect( orga.api.api_key ).to eq(api.api_key)
    end
  end


  describe "parent_projects" do
    it 'returns the parent projects' do
      user = UserFactory.create_new
      project = ProjectFactory.create_new user
      expect( project.save ).to be_truthy

      project2 = ProjectFactory.create_new user
      project2.parent_id = project.ids
      expect( project2.save ).to be_truthy

      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      project.organisation = orga
      expect( project.save ).to be_truthy

      project2.organisation = orga
      expect( project2.save ).to be_truthy

      orga = Organisation.first
      expect( orga.parent_projects.count ).to eq(1)
      expect( orga.projects.count ).to eq(2)
    end
  end


  describe "team_projects" do
    it 'returns the team projects' do
      user = UserFactory.create_new
      project = ProjectFactory.create_new user
      expect( project.save ).to be_truthy

      project2 = ProjectFactory.create_new user
      expect( project2.save ).to be_truthy

      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      owners = Team.new({:name => 'owners', :organisation_id => orga.ids })
      owners.organisation = orga
      expect( owners.save ).to be_truthy

      dev_team = Team.new({:name => 'dev_team', :organisation_id => orga.ids })
      dev_team.organisation = orga
      expect( dev_team.save ).to be_truthy

      project.organisation = orga
      expect( project.save ).to be_truthy

      project2.organisation = orga
      project2.team_ids = [dev_team.ids]
      expect( project2.save ).to be_truthy

      orga = Organisation.first
      expect( orga.projects.count ).to eq(2)
      expect( orga.team_projects(dev_team.ids).count ).to eq(1)

      project.team_ids = [dev_team.ids]
      expect( project.save ).to be_truthy
      expect( orga.team_projects(dev_team.ids).count ).to eq(2)
    end
  end


  describe "unknown_license_deps" do
    it "returns the unknown license_deps" do
      user = UserFactory.create_new
      project = ProjectFactory.create_new user
      expect( project.save ).to be_truthy

      orga = Organisation.new({:name => 'Orga'})
      expect( orga.save ).to be_truthy

      project.organisation = orga
      expect( project.save ).to be_truthy

      product = ProductFactory.create_new 1
      expect( product.save ).to be_truthy

      dep = ProjectdependencyFactory.create_new project, product
      expect( dep.save ).to be_truthy

      deps = orga.unknown_license_deps
      expect( deps ).to_not be_nil
      expect( deps ).to_not be_empty
      expect( deps.count ).to eq(1)
      expect( deps.first ).to eq('Java:versioneye/test_maven_1:')
    end
  end


  describe "component_list" do

    it "returns the correct component_list" do
      user = UserFactory.create_new
      expect( user.save ).to be_truthy

      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      project = ProjectFactory.create_new user
      project.organisation = orga
      expect( project.save ).to be_truthy
      expect( orga.projects.count ).to eq(1)

      child = ProjectFactory.create_new user
      child.organisation = orga
      child.parent_id = project.ids
      expect( child.save ).to be_truthy
      expect( project.children.count ).to eq(1)
      expect( orga.projects.count ).to eq(2)

      prod_1  = ProductFactory.create_for_maven 'org.testng', 'testng', '1.0.0'
      expect( prod_1.save ).to be_truthy
      prod_2  = ProductFactory.create_for_maven 'org.junit', 'junit', '2.0.0'
      prod_2.add_version '1.9.9'
      expect( prod_2.save ).to be_truthy

      dep_1 = ProjectdependencyFactory.create_new project, prod_1, true
      dep_1.version_requested = prod_1.version
      expect( dep_1.save ).to be_truthy

      dep_2 = ProjectdependencyFactory.create_new project, prod_2, true
      dep_2.version_requested = prod_2.version
      expect( dep_2.save ).to be_truthy

      dep_3 = ProjectdependencyFactory.create_new child, prod_2, true
      dep_3.version_requested = '1.9.9'
      expect( dep_3.save ).to be_truthy

      comps = orga.component_list

      expect( comps ).to_not be_nil
      expect( comps.count ).to eq(2)
      expect( comps['Java:org.testng/testng:1.0.0']['1.0.0'] ).to_not be_nil
      expect( comps['Java:org.junit/junit:2.0.0']['2.0.0'] ).to_not be_nil
      expect( comps['Java:org.junit/junit:2.0.0']['1.9.9'] ).to_not be_nil
    end

  end

end
