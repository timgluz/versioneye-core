require 'spec_helper'

describe ProjectService do

  let(:github_user) { FactoryGirl.create(:github_user)}

  describe "find" do
    it "returns the project with dependencies" do
      rc_1 = '200.0.0-RC1'
      zz_1 = '0.0.1'

      user    = UserFactory.create_new
      project = ProjectFactory.create_new user

      prod_1  = ProductFactory.create_new 1
      prod_2  = ProductFactory.create_new 2
      prod_2.versions = []
      prod_2.add_version rc_1
      prod_2.version = rc_1
      prod_2.save
      prod_3  = ProductFactory.create_new 3

      dep_1 = ProjectdependencyFactory.create_new project, prod_1, true, {:version_requested => '1000.0.0'}
      dep_2 = ProjectdependencyFactory.create_new project, prod_2, true, {:version_requested => zz_1, :version_current => rc_1}
      dep_3 = ProjectdependencyFactory.create_new project, prod_3, true, {:version_requested => '0.0.0'}

      project.dependencies.count.should eq(3)
      project.dependencies.each do |dep|
        dep.outdated = nil
        dep.release = nil
        dep.save
      end

      project.dependencies.each do |dep|
        dep.outdated.should be_nil
        dep.release.should be_nil
      end

      proj = ProjectService.find project.id.to_s
      proj.dependencies.count.should eq(3)
      proj.dependencies.each do |dep|
        dep.outdated.should_not be_nil
        dep.release.should_not be_nil
      end

      d1 = Projectdependency.find dep_1.id.to_s
      d1.release.should be_true

      d2 = Projectdependency.find dep_2.id.to_s
      d2.release.should be_false
    end
  end

  describe "type_by_filename" do
    it "returns RubyGems. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_Gemfile?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      url2 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_Gemfile.lock?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_RUBYGEMS)
      described_class.type_by_filename(url2).should eql(Project::A_TYPE_RUBYGEMS)
      described_class.type_by_filename("Gemfile").should eql(Project::A_TYPE_RUBYGEMS)
      described_class.type_by_filename("Gemfile.lock").should eql(Project::A_TYPE_RUBYGEMS)
      described_class.type_by_filename("app/Gemfile").should eql(Project::A_TYPE_RUBYGEMS)
      described_class.type_by_filename("app/Gemfile.lock").should eql(Project::A_TYPE_RUBYGEMS)
    end
    it "returns nil for wrong Gemfiles. OK" do
      described_class.type_by_filename("Gemfile/").should be_nil
      described_class.type_by_filename("Gemfile.lock/a").should be_nil
      described_class.type_by_filename("app/Gemfile/new.html").should be_nil
      described_class.type_by_filename("app/Gemfile.lock/new").should be_nil
    end

    it "returns Composer. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_composer.json?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_COMPOSER)
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_COMPOSER)
      described_class.type_by_filename("composer.json").should eql(Project::A_TYPE_COMPOSER)
      described_class.type_by_filename("composer.lock").should eql(Project::A_TYPE_COMPOSER)
      described_class.type_by_filename("app/composer.json").should eql(Project::A_TYPE_COMPOSER)
      described_class.type_by_filename("app/composer.lock").should eql(Project::A_TYPE_COMPOSER)
    end
    it "returns nil for wrong composer. OK" do
      described_class.type_by_filename("composer.json/").should be_nil
      described_class.type_by_filename("composer.lock/a").should be_nil
      described_class.type_by_filename("app/composer.json/new.html").should be_nil
      described_class.type_by_filename("app/composer.lock/new").should be_nil
    end

    it "returns PIP. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_requirements.txt?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_PIP)
      described_class.type_by_filename("requirements.txt").should eql(Project::A_TYPE_PIP)
      described_class.type_by_filename("app/requirements.txt").should eql(Project::A_TYPE_PIP)
    end
    it "returns nil for wrong pip file" do
      described_class.type_by_filename("requirements.txta").should be_nil
      described_class.type_by_filename("app/requirements.txt/new").should be_nil
    end

    it "returns NPM. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_package.json?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_NPM)
      described_class.type_by_filename("package.json").should eql(Project::A_TYPE_NPM)
      described_class.type_by_filename("app/package.json").should eql(Project::A_TYPE_NPM)
    end
    it "returns nil for wrong npm file" do
      described_class.type_by_filename("package.jsona").should be_nil
      described_class.type_by_filename("app/package.json/new").should be_nil
    end

    it "returns Gradle. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_dep.gradle?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_GRADLE)
      described_class.type_by_filename("dependencies.gradle").should eql(Project::A_TYPE_GRADLE)
      described_class.type_by_filename("app/dependencies.gradle").should eql(Project::A_TYPE_GRADLE)
      described_class.type_by_filename("app/deps.gradle").should eql(Project::A_TYPE_GRADLE)
    end
    it "returns nil for wrong gradle file" do
      described_class.type_by_filename("dependencies.gradlea").should be_nil
      described_class.type_by_filename("dep.gradleo1").should be_nil
      described_class.type_by_filename("app/dependencies.gradle/new").should be_nil
      described_class.type_by_filename("app/dep.gradle/new").should be_nil
    end

    it "returns Maven2. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_pom.xml?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should          eql(Project::A_TYPE_MAVEN2)
      described_class.type_by_filename("app/pom.xml").should eql(Project::A_TYPE_MAVEN2)
    end
    it "returns nil for wrong maven2 file" do
      described_class.type_by_filename("pom.xmla").should be_nil
      described_class.type_by_filename("app/pom.xml/new").should be_nil
    end

    it "returns Lein. OK" do
      url1 = "http://localhost:4567/veye_dev_projects/i5lSWS951IxJjU1rurMg_project.clj?AWSAccessKeyId=123&Expires=1360525084&Signature=HRPsn%2Bai%2BoSjm8zqwZFRtzxJvvE%3D"
      described_class.type_by_filename(url1).should eql(Project::A_TYPE_LEIN)
      described_class.type_by_filename("project.clj").should eql(Project::A_TYPE_LEIN)
      described_class.type_by_filename("app/project.clj").should eql(Project::A_TYPE_LEIN)
    end
    it "returns nil for wrong Lein file" do
      described_class.type_by_filename("project.clja").should be_nil
      described_class.type_by_filename("app/project.clj/new").should be_nil
    end

  end


  describe "badge_for_project" do
    it "returns the right badge up-to-date" do
      user = UserFactory.create_new
      product = ProductFactory.create_new
      product.version = '10.0.0'
      product.add_version '10.0.0'
      product.save
      project = ProjectFactory.create_new user
      project_dep = ProjectdependencyFactory.create_new project, product
      project_dep.version_current = '10.0.0'
      project_dep.version_requested = '10.0.0'
      project_dep.save
      ProjectdependencyService.update_outdated!(project_dep)
      project_dep.save
      ProjectService.outdated?(project).should be_false
      ProjectService.badge_for_project(project.id).should eq('up-to-date')
    end

    it "returns the right badge out-of-date" do
      user = UserFactory.create_new
      product = ProductFactory.create_new
      product.version = '10.0.0'
      product.add_version '10.0.0'
      product.save
      project = ProjectFactory.create_new user
      project_dep = ProjectdependencyFactory.create_new project, product
      project_dep.version_current = '9.0.0'
      project_dep.version_requested = '9.0.0'
      project_dep.save
      ProjectdependencyService.update_outdated!(project_dep)
      project_dep.save
      ProjectService.outdated?(project).should be_true
      ProjectService.badge_for_project(project.id).should eq('out-of-date')
    end
  end

  describe 'update_badge_for_project' do
    it 'updates the badge to up-to-date' do
      user = UserFactory.create_new
      product = ProductFactory.create_new
      product.version = '10.0.0'
      product.add_version '10.0.0'
      product.save
      project = ProjectFactory.create_new user
      project_dep = ProjectdependencyFactory.create_new project, product
      project_dep.version_current = '9.0.0'
      project_dep.version_requested = '9.0.0'
      project_dep.save
      ProjectdependencyService.update_outdated!(project_dep)
      project_dep.save
      ProjectService.outdated?(project).should be_true
      ProjectService.badge_for_project(project.id).should eq('out-of-date')

      project_dep.version_current = '10.0.0'
      project_dep.version_requested = '10.0.0'
      project_dep.save
      ProjectdependencyService.update_outdated!(project_dep)
      project_dep.save
      ProjectService.outdated?(project).should be_false
      ProjectService.update_badge_for_project(project).should eq('up-to-date')
    end

    it 'updates the badge to out-of-date' do
      user = UserFactory.create_new
      product = ProductFactory.create_new
      product.versions = Array.new
      product.version = '10.0.0'
      product.add_version '10.0.0'
      product.save
      project = ProjectFactory.create_new user
      project_dep = ProjectdependencyFactory.create_new project, product
      project_dep.version_current = '10.0.0'
      project_dep.version_requested = '10.0.0'
      project_dep.save
      ProjectdependencyService.update_outdated!(project_dep)
      project_dep.save
      ProjectService.outdated?(project).should be_false

      ProjectService.badge_for_project(project.id).should eq('up-to-date')

      project_dep.version_current = '9.0.0'
      project_dep.version_requested = '9.0.0'
      project_dep.save
      ProjectdependencyService.update_outdated!(project_dep)
      project_dep.save
      ProjectService.outdated?(project).should be_true
      ProjectService.update_badge_for_project(project).should eq('out-of-date')
    end
  end

end
