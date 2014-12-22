require 'spec_helper'

describe Project do

  before(:each) do
    @user = User.new({:fullname => 'Hans Tanz', :username => 'hanstanz',
      :email => 'hans@tanz.de', :password => 'password', :salt => 'salt',
      :terms => true, :datenerhebung => true})
    @user.save
  end

  
  describe "to_s" do 
    it 'returns to_s' do 
      project = Project.new({:language => 'Java', :project_type => 'Maven2', :name => 'pomi' })
      project.to_s.should eq("<Project Java/Maven2 pomi>")
    end
  end


  describe "children" do 
    it 'returns an empty array' do 
      project = Project.new({:language => 'Java', :project_type => 'Maven2', :name => 'pomi' })
      kids = project.children
      kids.should_not be_nil 
      kids.should be_empty
    end

    it 'returns an empty array' do 
      user = UserFactory.create_new 1079
      project = ProjectFactory.create_new user
      project.save 
      kid     = ProjectFactory.create_new user
      kid.parent_id = project.id.to_s
      kid.save  
      Project.all.count.should eq(2)
      kids = project.children
      kids.should_not be_nil 
      kids.count.should eq(1)
    end
  end


  describe "filename" do 
    it 'returns the nacked filename' do 
      project = Project.new({ :s3_filename => 'pom.xml' })
      project.filename.should eq("pom.xml")
    end
    it 'returns the filtered filename' do 
      project = Project.new({ :s3_filename => '85773722_pom.xml' })
      project.filename.should eq("pom.xml")
    end
  end


  describe "sum_own!" do 
    it 'sums own' do 
      project = Project.new({ :dep_number => 5, :out_number => 1, 
        :unknown_number => 2, :licenses_red => 2, :licenses_unknown => 2 })
      project.dep_number_sum.should eq(0)
      project.out_number_sum.should eq(0)
      project.unknown_number_sum.should eq(0) 
      project.licenses_red_sum.should eq(0)
      project.licenses_unknown_sum.should eq(0) 
      project.sum_own! 
      project.dep_number_sum.should eq( project.dep_number )
      project.out_number_sum.should eq( project.out_number )
      project.unknown_number_sum.should eq( project.unknown_number )
      project.licenses_red_sum.should eq( project.licenses_red )
      project.licenses_unknown_sum.should eq( project.licenses_unknown )
    end
  end


  describe "show_dependency_badge?" do 
    it 'shows the badge' do 
      project = Project.new({ :language => 'Java' })
      project.show_dependency_badge?().should be_truthy
    end
    it 'shows not the badge' do 
      project = Project.new({ :language => 'Puki' })
      project.show_dependency_badge?().should be_falsey
    end
  end


  describe "license_whitelist?" do 
    it 'returns nil' do 
      project = Project.new
      project.license_whitelist.should be_nil
    end
    it 'returns nil' do 
      lwl = LicenseWhitelistFactory.create_new 'OkForMe'
      lwl.save.should be_truthy
      project = Project.new({:license_whitelist_id => lwl.id.to_s})
      project.license_whitelist.should_not be_nil
      project.license_whitelist.id.to_s.should eq(lwl.id.to_s)
    end
  end


  describe "private_project_count_by_user" do 
    it 'returns 0' do 
      Project.private_project_count_by_user(nil).should eq(0)
    end
    it 'returns 0 because user has only public projects' do
      user = UserFactory.create_new 
      new_project = ProjectFactory.create_new user
      new_project.private_project = false 
      new_project.save 
      Project.private_project_count_by_user( user.id.to_s ).should eq(0)
    end
    it 'returns 1 because user has only 1 private project' do
      user = UserFactory.create_new 
      new_project = ProjectFactory.create_new user
      new_project.private_project = true 
      new_project.save 
      Project.private_project_count_by_user( user.id.to_s ).should eq(1)
    end
    it 'returns 1. User has 1 private and 1 public project' do
      user = UserFactory.create_new 
      new_project = ProjectFactory.create_new user
      new_project.private_project = false
      new_project.save 
      new_project2 = ProjectFactory.create_new user
      new_project2.private_project = true 
      new_project2.save 
      Project.private_project_count_by_user( user.id.to_s ).should eq(1)
    end
    it 'returns 2. User has 2 private' do
      user = UserFactory.create_new 
      new_project = ProjectFactory.create_new user
      new_project.private_project = true 
      new_project.save 
      new_project2 = ProjectFactory.create_new user
      new_project2.private_project = true 
      new_project2.save 
      Project.private_project_count_by_user( user.id.to_s ).should eq(2)
    end
  end


  describe "email_for" do

    it "returns user default email" do
      project = Project.new
      user = User.new
      user.email = "hallo@hallo.de"
      Project.email_for(project, user).should eql("hallo@hallo.de")
    end

    it "returns user default email because the project email does not exist" do
      project = Project.new
      user = User.new
      user.email = "hallo@hallo.de"
      project.email = "hadoop@palm.de"
      Project.email_for(project, user).should eql("hallo@hallo.de")
    end

    it "returns project email" do
      project = Project.new
      user_email = UserEmail.new
      user_email.user_id = @user._id.to_s
      user_email.email = "ping@pong.de"
      user_email.save
      @user.email = "hallo@hallo.de"
      project.email = "ping@pong.de"
      Project.email_for(project, @user).should eql("ping@pong.de")
    end

    it "returns user email because project email is not verified" do
      project = Project.new
      user_email = UserEmail.new
      user_email.user_id = @user._id.to_s
      user_email.email = "ping@pong.de"
      user_email.verification = "verify_me"
      user_email.save
      @user.email = "hallo@hallo.de"
      project.email = "ping@pong.de"
      Project.email_for(project, @user).should eql("hallo@hallo.de")
    end

  end

  describe "make_project_key" do
    before(:each) do
      @test_user = UserFactory.create_new 1001
      @test_user.nil?.should be_falsey
      @test_project = ProjectFactory.create_new @test_user
    end

    it "project factory generated project_key passes validation" do
      @test_project.errors.full_messages.empty?.should be_truthy
    end

    it "if generates unique project_key if there already exsists similar projects" do
      new_project = ProjectFactory.create_new @test_user
      new_project.valid?.should be_truthy
      new_project.project_key.should =~ /(\d+)\z/
      new_project.remove
    end

    it "if generates unique project_key only once" do
      new_project = ProjectFactory.create_new @test_user
      new_project.valid?.should be_truthy
      new_project.project_key.should =~ /(\d+)\z/
      project_key = new_project.project_key
      new_project.make_project_key!
      new_project.project_key.should eql(project_key)
      new_project.remove
    end
  end

  describe "collaborator" do
    before(:each) do
      @test_user = UserFactory.create_new 10021
      @test_user.nil?.should be_falsey
      @test_project = ProjectFactory.create_new @test_user
    end

    it "project factory generated project_key passes validation" do
      col_user     = UserFactory.create_new 10022
      collaborator = ProjectCollaborator.new(:project_id => @test_project._id,
                                             :owner_id => @test_user._id,
                                             :caller_id => @test_user._id )
      collaborator.save
      @test_project.collaborators << collaborator
      @test_project.collaborator( col_user ).should be_nil
      @test_project.collaborator( @test_user ).should be_nil
      @test_project.collaborator( nil ).should be_nil

      @test_project.collaborator?( col_user ).should be_falsey
      @test_project.collaborator?( nil ).should be_falsey
      @test_project.collaborator?( @test_user ).should be_truthy

      collaborator.user_id = col_user._id
      collaborator.save
      collaborator_db = @test_project.collaborator( col_user )
      collaborator_db.should_not be_nil
      collaborator_db.user.username.should eql( col_user.username )
      @test_project.collaborator?( col_user ).should be_truthy

      @test_project.remove_collaborators
      @test_project.collaborators.size.should eq(0)
      @test_project.collaborators.count.should eq(0)
      @test_project.collaborator( col_user ).should be_nil
    end
  end

  describe "visible_for_user?" do
    before(:each) do
      @test_user = UserFactory.create_new 1023
      @test_user.nil?.should be_falsey
      @test_project = ProjectFactory.create_new @test_user
      @test_project.public = false
      @test_project.save
    end

    after(:each) do
      @test_user.remove
      @test_project.remove
    end

    it "project factory generated project_key passes validation" do
      col_user = UserFactory.create_new 1024
      collaborator = ProjectCollaborator.new(:project_id => @test_project._id,
                                             :owner_id => @test_user._id,
                                             :caller_id => @test_user._id )
      collaborator.save
      @test_project.collaborators << collaborator
      @test_project.visible_for_user?( col_user ).should be_falsey
      @test_project.visible_for_user?( nil ).should be_falsey
      @test_project.visible_for_user?( @test_user ).should be_truthy
      @test_project.public = true
      @test_project.save
      @test_project.visible_for_user?( col_user ).should be_truthy
      @test_project.public = false
      @test_project.save
      @test_project.visible_for_user?( col_user ).should be_falsey
      @test_project.visible_for_user?( @test_user ).should be_truthy
      collaborator.user_id = col_user._id
      collaborator.save
      @test_project.visible_for_user?( col_user ).should be_truthy
      @test_project.visible_for_user?( @test_user ).should be_truthy
    end
  end

  describe "unmuted_dependencies" do
    it "returns muted and unmuted dependencies" do
      user = UserFactory.create_new 1066
      user.nil?.should be_falsey
      project = ProjectFactory.create_new user
      project.public = false
      project.save

      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3

      ProjectdependencyFactory.create_new project, product_1
      ProjectdependencyFactory.create_new project, product_2
      dep_3 = ProjectdependencyFactory.create_new project, product_3

      unmuted = project.unmuted_dependencies
      unmuted.should_not be_nil
      unmuted.count.should eq(3)
      project.muted_prod_keys.should be_empty

      dep_3.muted = true
      dep_3.save

      unmuted = project.unmuted_dependencies
      unmuted.should_not be_nil
      unmuted.count.should eq(2)

      prod_keys = project.muted_prod_keys
      prod_keys.should_not be_empty
      prod_keys.count.should eq(1)
      prod_keys.first.should eql("#{dep_3.language}_#{dep_3.prod_key}_#{dep_3.version_current}")

      muted = project.muted_dependencies
      muted.should_not be_nil
      muted.count.should eq(1)
      muted.first._id.should eql(dep_3._id)

      user.remove
      project.remove
    end
  end

  describe "overwrite_dependencies" do
    it "overwrites dependencies" do
      user = UserFactory.create_new 1066
      user.nil?.should be_falsey
      project = ProjectFactory.create_new user
      project.save

      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3

      dep_1 = ProjectdependencyFactory.create_new project, product_1
      dep_1.version_current = "2.0.0"
      dep_1.version_requested = "1.0.0"
      dep_1.save

      dep_2 = ProjectdependencyFactory.create_new project, product_2
      dep_2.version_current = "2.0.0"
      dep_2.version_requested = "1.0.0"
      dep_2.muted = true
      dep_2.save

      dep_3 = ProjectdependencyFactory.create_new project, product_3
      dep_3.version_current = "2.0.0"
      dep_3.version_requested = "1.0.0"
      dep_3.muted = true
      dep_3.save

      old_deps = [dep_1.id.to_s, dep_2.id.to_s, dep_3.id.to_s, ]

      unmuted = project.unmuted_dependencies
      unmuted.count.should eq(1)

      dep_4 = Projectdependency.new
      dep_4.language = dep_1.language
      dep_4.prod_key = dep_1.prod_key
      dep_4.version_current = "2.0.0"
      dep_4.version_requested = "1.0.0"
      dep_4.save
      dep_5 = Projectdependency.new
      dep_5.language = dep_2.language
      dep_5.prod_key = dep_2.prod_key
      dep_5.version_current = "2.1.0"   # Current version goes 1 up. That will reset the muted to false!
      dep_5.version_requested = "1.0.0"
      dep_5.save
      dep_6 = Projectdependency.new
      dep_6.language = dep_3.language
      dep_6.prod_key = dep_3.prod_key
      dep_6.version_current = "2.0.0"
      dep_6.version_requested = "1.0.0"
      dep_6.save
      new_deps = Array.new
      new_deps.push dep_4
      new_deps.push dep_5
      new_deps.push dep_6

      project.overwrite_dependencies( new_deps )

      proj_db = Project.find project.id

      unmuted = proj_db.unmuted_dependencies
      unmuted.count.should eq(2)

      muted = proj_db.muted_dependencies
      muted.count.should eq(1)
      muted.first.prod_key.should eql( dep_6.prod_key )

      proj_db.dependencies.each do |dep|
        old_deps.include?( dep.id.to_s ).should be_falsey
      end
    end
  end

  describe 'update_from' do

    it 'updates from new project' do

      user = UserFactory.create_new 1077
      project = ProjectFactory.create_new user
      project.description = 'project_1'
      project.license = 'GPL'
      project.url = 'https://github/awesome/awesome_1'
      project.s3_filename = 'https://amazon.s3.s1'
      project.dep_number = 3
      project.out_number = 0
      project.unknown_number = 0
      project.save

      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3

      dep_1 = ProjectdependencyFactory.create_new project, product_1
      dep_2 = ProjectdependencyFactory.create_new project, product_2
      dep_3 = ProjectdependencyFactory.create_new project, product_3

      proj_1 = Project.find project.id
      proj_1.dependencies.count.should eq(3)

      # Create new project to update the old one

      new_project = ProjectFactory.create_new user
      new_project.description = 'new_project'
      new_project.license = 'MIT'
      new_project.url = 'https://github/awesome/awesome_2'
      new_project.s3_filename = 'https://amazon.s3.s2'
      new_project.dep_number = 4
      new_project.out_number = 1
      new_project.unknown_number = 1
      new_project.save

      product_4 = ProductFactory.create_new 4
      product_5 = ProductFactory.create_new 5
      product_6 = ProductFactory.create_new 6
      product_7 = ProductFactory.create_new 7

      dep_4 = ProjectdependencyFactory.create_new new_project, product_4
      dep_5 = ProjectdependencyFactory.create_new new_project, product_5
      dep_6 = ProjectdependencyFactory.create_new new_project, product_6
      dep_7 = ProjectdependencyFactory.create_new new_project, product_7

      new_proj = Project.find_by_id new_project.id
      new_proj.dependencies.count.should eq(4)

      project.update_from new_project
      project = Project.find_by_id project.id
      project.dependencies.count.should eq(4)
      project.description.should eq('new_project')
      project.license.should eq('MIT')
      project.url.should eq('https://github/awesome/awesome_2')
      project.s3_filename.should eq('https://amazon.s3.s2')
      project.dep_number.should eq(4)
      project.out_number.should eq(1)
      project.unknown_number.should eq(1)
    end

  end

  describe 'create_random_value' do
    it 'returns a random value with the length of 20' do
      rd = Project.create_random_value
      rd.should_not be_nil
      rd.length.should eq(20)
    end
  end

  describe 'save_dependencies' do

    it 'stores the dependencies' do

      user = UserFactory.create_new 1077

      # Cretate a project but don't persist it!
      project = ProjectFactory.create_new user, nil, false

      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2

      # Add unstored deps to unstored project
      dep_1 = ProjectdependencyFactory.create_new project, product_1, false
      dep_2 = ProjectdependencyFactory.create_new project, product_2, false

      project.dependencies.size.should eq(2)

      # Returns nil because project is not persisted
      proj_db = Project.find_by_id project.id
      proj_db.should be_nil

      # Persist project. But it does not cascade to dependencies
      project.save
      proj_db = Project.find_by_id project.id
      proj_db.dependencies.count.should eq(0)

      # Persist dependencies
      project.save_dependencies

      # Reloaded project has now all dependencies
      proj_db = Project.find_by_id project.id
      proj_db.dependencies.count.should eq(2)
    end

  end

  describe 'remove_dependencies' do

    it 'removes the dependencies' do

      user = UserFactory.create_new 1077
      project = ProjectFactory.create_new user

      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2

      dep_1 = ProjectdependencyFactory.create_new project, product_1
      dep_2 = ProjectdependencyFactory.create_new project, product_2

      proj_db = Project.find_by_id project.id
      proj_db.dependencies.count.should eq(2)

      proj_db.remove_dependencies

      proj_db = Project.find_by_id project.id
      proj_db.dependencies.count.should eq(0)
      proj_db.dependencies.size.should eq(0)
    end

  end

  describe 'known_dependencies' do

    it 'returns the known dependencies' do

      user = UserFactory.create_new 1077
      project = ProjectFactory.create_new user

      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2

      dep_1 = ProjectdependencyFactory.create_new project, product_1
      dep_2 = ProjectdependencyFactory.create_new project, product_2
      dep_2.prod_key = nil
      dep_2.save

      known_deps = project.known_dependencies
      known_deps.should_not be_nil
      known_deps.count.should eq(1)
      known_deps.first.id.to_s.should eq(dep_1.id.to_s)
    end

  end

  describe 'sorted_dependencies_by_rank' do

    it 'returns sorted dependencies' do
      user = UserFactory.create_new 1077
      project = ProjectFactory.create_new user

      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3

      dep_1 = ProjectdependencyFactory.create_new project, product_1
      dep_2 = ProjectdependencyFactory.create_new project, product_2
      dep_3 = ProjectdependencyFactory.create_new project, product_3
      dep_3.version_requested = '0.0.0'
      dep_3.outdated = true
      dep_3.save

      deps = project.dependencies.first.id.to_s.should eq( dep_1.id.to_s )

      dep_1[:status_rank] = 3
      dep_2[:status_rank] = 2
      dep_3[:status_rank] = 1

      deps = project.sorted_dependencies_by_rank
      deps.first.id.to_s.should eq(dep_3.id.to_s)
      deps.last.id.to_s.should eq(dep_1.id.to_s)
    end

  end

end
