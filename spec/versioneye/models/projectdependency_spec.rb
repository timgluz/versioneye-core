require 'spec_helper'

describe Projectdependency do

  let(:user)    { UserFactory.create_new }
  let(:project) { ProjectFactory.create_new user }


  describe "find_or_init_product" do
    it "returns the right product" do
      project.project_type = Project::A_TYPE_BOWER
      project.save

      bootstrap_css = ProductFactory.create_for_bower 'bootstrap', '3.1.1'
      bootstrap_css.prod_key = 'twbs/bootstrap'
      bootstrap_css.language = 'CSS'
      bootstrap_css.save

      bootstrap = ProductFactory.create_for_bower 'bootstrap', '3.1.1'
      bootstrap.prod_key = 'bootstrap'
      bootstrap.language = 'CSS'
      bootstrap.prod_type = Project::A_TYPE_GITHUB
      bootstrap.save

      dep_1 = ProjectdependencyFactory.create_new project, bootstrap_css, {:version_requested => '3.1.1'}
      dep_1.prod_key = nil
      dep_1.save
      project.dependencies.count.should eq(1)

      prod = dep_1.find_or_init_product
      prod.should_not be_nil
      prod.prod_key.should eq('twbs/bootstrap')

      project.project_type = Project::A_TYPE_GITHUB
      project.save
      dep = project.dependencies.first
      dep.prod_key = 'bootstrap'
      prod = dep.find_or_init_product
      prod.prod_key.should eq('bootstrap')
    end

    it "returns the right Maven product by group_id and artifact_id" do
      project.project_type = Project::A_TYPE_MAVEN2
      project.save

      junit = ProductFactory.create_for_maven 'org.junit', 'junit', '3.2.1'
      junit.save

      dep_1 = ProjectdependencyFactory.create_new project, junit
      dep_1.prod_key = ''
      dep_1.save
      project.dependencies.count.should eq(1)

      prod = dep_1.find_or_init_product
      prod.should_not be_nil
      prod.prod_key.should eq('org.junit/junit')
    end

    it "returns the right Ruby product" do
      project.project_type = Project::A_TYPE_RUBYGEMS
      project.save

      log4r = ProductFactory.create_for_gemfile 'log4r', '3.2.1'
      log4r.save

      dep_1 = ProjectdependencyFactory.create_new project, log4r
      dep_1.save
      project.dependencies.count.should eq(1)

      prod = dep_1.find_or_init_product
      prod.should_not be_nil
      prod.prod_key.should eq('log4r')
    end

    it "inits the product" do
      dep_1 = ProjectdependencyFactory.create_new project, nil
      dep_1.save
      project.dependencies.count.should eq(1)

      prod = dep_1.find_or_init_product
      prod.should_not be_nil
      prod.prod_key.should be_nil
      prod.name.should eq(dep_1.name)
    end
  end

  describe 'possible_prod_key' do
    it 'returns the name' do
      dep = Projectdependency.new
      dep.name = "AhA"
      dep.possible_prod_key.should eql("aha")
    end
    it 'returns the group_id/artifact_id' do
      dep = Projectdependency.new
      dep.name = "AhA"
      dep.group_id = "org.junit"
      dep.artifact_id = "testng"
      dep.possible_prod_key.should eql("org.junit/testng")
    end
  end


  describe 'cwl_key' do
    it 'returns gav' do
      dep = Projectdependency.new(:group_id => "org.spring", :artifact_id => "sponk-core", :version_requested => "1.0.0")
      expect( dep.cwl_key ).to eql("org.spring:sponk-core:1.0.0")
    end
    it 'returns language prod_key and version' do
      dep = Projectdependency.new(:language => "Ruby", :prod_key => "rails", :version_requested => "1.0.0")
      expect( dep.cwl_key ).to eql("ruby:rails:1.0.0")
    end
  end


  describe 'find_by_id' do
    it 'returns the dep' do
      dep = Projectdependency.new(:language => "Java", :prod_key => 'org.spring/sponk-core', :group_id => "org.spring", :artifact_id => "sponk-core", :version_requested => "1.0.0")
      expect( dep.save ).to be_truthy
      expect( Projectdependency.find_by_id(dep.ids) ).to_not be_nil
    end
    it 'returns nil' do
      expect( Projectdependency.find_by_id( 'faf' ) ).to be_nil
    end
  end


  describe 'version' do
    it 'returns version_requested' do
      dep = Projectdependency.new( :version_requested => "1.0.0" )
      expect( dep.version ).to eql( dep.version_requested )
    end
  end


  describe 'language_esc' do
    it 'returns encoded language' do
      dep = Projectdependency.new( :language => "Node.JS" )
      expect( dep.language_esc ).to eql( 'nodejs' )
    end
  end


  describe 'product' do

    it 'returns the right product' do
      project.project_type = Project::A_TYPE_RUBYGEMS
      project.save

      log4r = ProductFactory.create_for_gemfile 'log4r', '3.2.1'
      log4r.save

      dep_1 = ProjectdependencyFactory.create_new project, log4r
      dep_1.version_label = '3.2.1'
      dep_1.version_current = '3.2.1'
      dep_1.save
      project.dependencies.count.should eq(1)

      dep_1.known?().should be_truthy
      pr = dep_1.product
      pr.should_not be_nil
      pr.prod_key.should eq('log4r')
      dep_1.to_s.should eq("<Projectdependency: #{project} depends on log4r (3.2.1/) current: 3.2.1 >")
    end

    it 'returns the right product for bower' do
      project.project_type = Project::A_TYPE_BOWER
      project.save

      log4r = ProductFactory.create_for_bower 'log4r', '3.2.1'
      log4r.save

      dep_1 = ProjectdependencyFactory.create_new project, log4r
      dep_1.version_label = '3.2.1'
      dep_1.version_current = '3.2.1'
      dep_1.save
      project.dependencies.count.should eq(1)

      dep_1.known?().should be_truthy
      pr = dep_1.product
      expect( pr ).to_not be_nil
      expect( pr.prod_key).to eq('log4r')
      expect( dep_1.to_s ).to eq("<Projectdependency: #{project} depends on log4r (3.2.1/) current: 3.2.1 >")
    end

    it 'returns the right product for maven' do
      project.project_type = Project::A_TYPE_MAVEN2
      project.save

      log4r = ProductFactory.create_for_maven 'org.spring', 'spring-core', '3.2.1'
      log4r.save

      dep_1 = ProjectdependencyFactory.create_new project, log4r
      dep_1.version_label = '3.2.1'
      dep_1.version_current = '3.2.1'
      dep_1.save
      project.dependencies.count.should eq(1)

      dep_1.known?().should be_truthy
      pr = dep_1.product
      expect( pr ).to_not be_nil
      expect( pr.prod_key).to eq('org.spring/spring-core')
      expect( pr.group_id).to eq('org.spring')
      expect( pr.artifact_id).to eq('spring-core')
    end

  end

end
