require 'spec_helper'

describe OrganisationService do


  describe "inventory_diff" do
    it "returns the inventory_diff" do
      Plan.create_defaults

      user = UserFactory.create_new
      expect( user.save ).to be_truthy

      @user1 = UserFactory.create_new 392
      @orga = OrganisationService.create_new_for @user1

      team = Team.new(:name => 'devs', :organisation => @orga)
      expect( team.save ).to be_truthy

      TeamService.add 'devs', @orga.ids, user.username, @user1
      expect( @orga.teams.count ).to eq(2)

      project = ProjectFactory.create_new user, {:name => 'project_1'}, true, @orga
      project.language = 'Java'
      project.teams = [team]
      expect( project.save ).to be_truthy
      expect( @orga.projects.count ).to eq(1)

      project2 = ProjectFactory.create_new user, {:name => 'project_2'}, true, @orga
      project2.language = 'Java'
      project2.teams = [@orga.owner_team]
      expect( project2.save ).to be_truthy
      expect( project2.teams.count ).to eq(1)
      expect( project2.teams.first.name ).to eq("Owners")
      expect( @orga.projects.count ).to eq(2)
      expect( Project.count ).to eq(2)

      junit  = ProductFactory.create_for_maven 'org.junit', 'junit', '2.0.0'
      junit.add_version '1.9.9'
      expect( junit.save ).to be_truthy

      dep_1 = ProjectdependencyFactory.create_new project, junit, true
      dep_1.version_requested = junit.version
      expect( dep_1.save ).to be_truthy

      dep_2 = ProjectdependencyFactory.create_new project2, junit, true
      dep_2.version_label = '1.9.9'
      dep_2.version_requested = '1.9.9'
      expect( dep_2.save ).to be_truthy
      expect( dep_2.project.ids.eql?(project2.ids) ).to be_truthy

      expect( @orga.projects[0].dependencies.count ).to eq(1)
      expect( @orga.projects[1].dependencies.count ).to eq(1)

      diff = OrganisationService.inventory_diff @orga,
                                         {:team => team.ids, :language => nil, :version => nil, :after_filter => nil},
                                         {:team => "ALL", :language => nil, :version => nil, :after_filter => nil}
      expect( diff.items_added ).to eq(["Java::org.junit/junit::1.9.9::UNKNOWN::0"])
      expect( diff.items_removed ).to be_empty

      diff = OrganisationService.inventory_diff @orga,
                                         {:team => "ALL", :language => nil, :version => nil, :after_filter => nil},
                                         {:team => team.ids, :language => nil, :version => nil, :after_filter => nil}
      expect( diff.items_removed ).to eq(["Java::org.junit/junit::1.9.9::UNKNOWN::0"])
      expect( diff.items_added ).to be_empty
    end
  end


  describe "inventory_diff_async" do
    it "returns the inventory_diff" do
      Plan.create_defaults

      user = UserFactory.create_new
      expect( user.save ).to be_truthy

      @user1 = UserFactory.create_new 392
      @orga = OrganisationService.create_new_for @user1

      team = Team.new(:name => 'devs', :organisation => @orga)
      expect( team.save ).to be_truthy

      TeamService.add 'devs', @orga.ids, user.username, @user1
      expect( @orga.teams.count ).to eq(2)

      project = ProjectFactory.create_new user, {:name => 'project_1'}, true, @orga
      project.language = 'Java'
      project.teams = [team]
      expect( project.save ).to be_truthy
      expect( @orga.projects.count ).to eq(1)

      project2 = ProjectFactory.create_new user, {:name => 'project_2'}, true, @orga
      project2.language = 'Java'
      project2.teams = [@orga.owner_team]
      expect( project2.save ).to be_truthy
      expect( project2.teams.count ).to eq(1)
      expect( project2.teams.first.name ).to eq("Owners")
      expect( @orga.projects.count ).to eq(2)
      expect( Project.count ).to eq(2)

      junit  = ProductFactory.create_for_maven 'org.junit', 'junit', '2.0.0'
      junit.add_version '1.9.9'
      expect( junit.save ).to be_truthy

      dep_1 = ProjectdependencyFactory.create_new project, junit, true
      dep_1.version_requested = junit.version
      expect( dep_1.save ).to be_truthy

      dep_2 = ProjectdependencyFactory.create_new project2, junit, true
      dep_2.version_label = '1.9.9'
      dep_2.version_requested = '1.9.9'
      expect( dep_2.save ).to be_truthy
      expect( dep_2.project.ids.eql?(project2.ids) ).to be_truthy

      expect( @orga.projects[0].dependencies.count ).to eq(1)
      expect( @orga.projects[1].dependencies.count ).to eq(1)

      worker = Thread.new{ InventoryWorker.new.work }

      diff_id = OrganisationService.inventory_diff_async( @orga.name,
                                         {:team => team.ids, :language => nil, :version => nil, :after_filter => nil},
                                         {:team => "ALL", :language => nil, :version => nil, :after_filter => nil})
      expect( diff_id ).to_not be_nil
      idiff = InventoryDiff.find diff_id
      while idiff.finished == false do
        sleep 1
        idiff = InventoryDiff.find diff_id
        p "reload inventory diff: #{diff_id}"
      end
      expect( idiff.items_added.count ).to eq(1)
      expect( idiff.items_removed.count ).to eq(0)
      worker.exit
    end
  end


  describe "transfer" do

    it "transfers a project to the orga" do
      LicenseWhitelist.delete_all
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy

      project = ProjectFactory.create_new user
      expect( project.save ).to be_truthy

      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      expect( OrganisationService.transfer project, orga ).to be_truthy
      expect( project.organisation ).to_not be_nil
      expect( project.license_whitelist_id ).to be_nil
      expect( project.component_whitelist_id ).to be_nil
    end

    it "transfers a project to the orga" do
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy

      project = ProjectFactory.create_new user
      expect( project.save ).to be_truthy

      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil

      cwl = ComponentWhitelist.new({:name => 'cwl', :default => true})
      cwl.organisation = orga
      expect( cwl.save ).to be_truthy

      lwl = LicenseWhitelist.new({:name => 'lwl', :default => true})
      lwl.organisation = orga
      expect( lwl.save ).to be_truthy

      expect( OrganisationService.transfer project, orga ).to be_truthy
      expect( project.organisation ).to_not be_nil
      expect( project.license_whitelist_id ).to_not be_nil
      expect( project.component_whitelist_id ).to_not be_nil
    end

  end


  describe "delete" do
    it "deletes an orga" do
      LicenseWhitelist.delete_all
      Plan.delete_all
      Plan.create_defaults

      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy

      project = ProjectFactory.create_new user
      expect( project.save ).to be_truthy

      orga = OrganisationService.create_new user, "myorga"
      expect( orga ).to_not be_nil
      expect( orga.save ).to be_truthy

      orga = Organisation.where(:name => 'myorga').first
      cwl = ComponentWhitelist.new({:name => 'cwl', :default => true})
      cwl.organisation = orga
      expect( cwl.save ).to be_truthy

      lwl = LicenseWhitelist.new({:name => 'lwl', :default => true})
      lwl.organisation = orga
      expect( lwl.save ).to be_truthy
      expect( orga.license_whitelists.count ).to eq(2)

      expect( OrganisationService.transfer project, orga ).to be_truthy
      expect( OrganisationService.delete orga ).to be_truthy
      expect( Project.count ).to eq(0)
      expect( LicenseWhitelist.count ).to eq(0)
      expect( ComponentWhitelist.count ).to eq(0)
      expect( Team.count ).to eq(0)
    end
  end


  describe "team_by" do

    it "finds the teams which belong to the given user" do
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy

      user1 = UserFactory.create_new 2
      user1.fullname = 'Han Solo'
      expect( user1.save ).to be_truthy

      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
      expect( orga ).to_not be_nil

      team = Team.new(:name => 'frontend', :organisation => orga.ids)
      expect( team.save ).to be_truthy

      team2 = Team.new(:name => 'backend', :organisation => orga.ids)
      expect( team2.save ).to be_truthy

      TeamService.add "frontend", orga.ids, user.username, user
      TeamService.add "backend" , orga.ids, user1.username, user

      orga = Organisation.first
      expect( orga ).to_not be_nil
      expect( orga.name ).to eq('myorga')
      expect( orga.teams.count ).to eq(3)

      teams = orga.teams_by user
      expect( teams.count ).to eq(2)
      expect( teams[1].name ).to eq('frontend')
    end

  end


  describe "create_new" do

    it "creates a new organisation" do
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
      expect( orga ).to_not be_nil

      orga = Organisation.first
      expect( orga ).to_not be_nil
      expect( orga.name ).to eq('myorga')
      expect( orga.teams.count ).to eq(1)
      expect( orga.teams.first.name ).to eq( Team::A_OWNERS )
      expect( orga.teams.first.members.count ).to eq(1)
      expect( orga.teams.first.members.first.user.fullname ).to eq('HansTanz')
      expect( orga.teams.first.members.first.user.ids ).to eq(user.ids)
    end

    it "throws an exception because name exist already" do
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
      expect( orga ).to_not be_nil
      expect{ OrganisationService.create_new(user, "myorga") }.to raise_exception
    end


    it "throws an exception because user is not and admin" do
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      Settings.instance.orga_creation_admin_only = true
      expect{ OrganisationService.create_new(user, "myorga") }.to raise_exception
      Settings.instance.orga_creation_admin_only = false
    end

  end


  describe "owner?" do

    it "returns true because owner" do
      user2 = UserFactory.create_new 2
      user = UserFactory.create_new
      user.fullname = 'HansTanz'
      expect( user.save ).to be_truthy
      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
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
      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
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
      expect( OrganisationService.owner?(  orga, user ) ).to be_truthy
      expect( OrganisationService.member?( orga, user ) ).to be_truthy

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
      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
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
      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
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
      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
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

      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
      expect( orga ).to_not be_nil

      orga = OrganisationService.create_new user, "yourOrga"
      orga.plan = Plan.micro
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

      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
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

      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
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

      Plan.create_defaults
      orga = OrganisationService.create_new user, "myorga"
      orga.plan = Plan.micro
      expect( orga ).to_not be_nil

      orgas = OrganisationService.orgas_allowed_to_transfer user
      expect( orgas ).to_not be_nil
      expect( orgas.count ).to eq(1)
    end

  end


end
