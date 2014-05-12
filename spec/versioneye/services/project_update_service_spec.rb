require 'spec_helper'

describe ProjectUpdateService do

  describe 'update' do

    it 'will update the project' do
      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.s3_filename = 'pom.xml'
      project.scm_fullname = 'versioneye/versioneye_maven_plugin'
      project.scm_branch = 'master'
      project.source = Project::A_SOURCE_GITHUB

      project = described_class.update project
      project.should_not be_nil
      project.dependencies.count.should == 11
    end

  end

  describe 'update_collaborators_projects' do

    it 'will remove the collaborator because project is nil' do
      pc = ProjectCollaborator.new({:project_id => "87", :owner_id => "2", :user_id => "1", :caller_id => "2"})
      pc.active = true
      pc.period = Project::A_PERIOD_WEEKLY
      pc.save.should be_true

      ProjectCollaborator.count.should == 1

      described_class.update_collaborators_projects Project::A_PERIOD_WEEKLY

      ProjectCollaborator.count.should == 0
    end

  end

  describe 'update_all' do

    it 'will update all and send 0 emails because everything is up-to-date' do
      ActionMailer::Base.deliveries.clear

      user = UserFactory.create_new
      hans = UserFactory.create_new 2

      project = ProjectFactory.default user
      project.s3_filename = 'pom.xml'
      project.scm_fullname = 'versioneye/versioneye_maven_plugin'
      project.scm_branch = 'master'
      project.source = Project::A_SOURCE_GITHUB
      project.period = Project::A_PERIOD_WEEKLY
      project.dependencies.count.should == 3
      project.save

      pc = ProjectCollaborator.new({:project_id => project.id.to_s, :owner_id => user.id.to_s, :user_id => hans.id.to_s, :caller_id => user.id.to_s})
      pc.active = true
      pc.period = Project::A_PERIOD_WEEKLY
      pc.save.should be_true

      described_class.update_all Project::A_PERIOD_WEEKLY
      project.reload
      project.dependencies.count.should == 11

      ActionMailer::Base.deliveries.size.should == 0
    end

    it 'will update all and send 2 emails because it is not up-to-date' do
      ActionMailer::Base.deliveries.clear

      product = ProductFactory.create_for_maven 'org.apache.maven', 'maven-compat', '10.0.0'
      product.save.should be_true

      user = UserFactory.create_new
      hans = UserFactory.create_new 2

      project = ProjectFactory.default user
      project.s3_filename = 'pom.xml'
      project.scm_fullname = 'versioneye/versioneye_maven_plugin'
      project.scm_branch = 'master'
      project.source = Project::A_SOURCE_GITHUB
      project.period = Project::A_PERIOD_WEEKLY
      project.dependencies.count.should == 3
      project.save

      pc = ProjectCollaborator.new({:project_id => project.id.to_s, :owner_id => user.id.to_s, :user_id => hans.id.to_s, :caller_id => user.id.to_s})
      pc.active = true
      pc.period = Project::A_PERIOD_WEEKLY
      pc.save.should be_true

      described_class.update_all Project::A_PERIOD_WEEKLY
      project.reload
      project.dependencies.count.should == 11

      ActionMailer::Base.deliveries.size.should == 2
    end

  end

end
