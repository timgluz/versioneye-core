require 'spec_helper'

describe BitbucketUpdater do

  describe 'update' do

    it 'returns nil' do
      user = UserFactory.create_new
      project = ProjectFactory.default user

      new_project = described_class.new.update project
      new_project.should be_nil
    end

    it 'returns the updated project' do
      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.s3_filename = 'Gemfile'
      project.scm_fullname = 'reiz/test_gemi'
      project.scm_branch = 'master'
      expect( project.save ).to be_truthy
      id = project.ids 

      described_class.new.update project
      project = Project.find id 
      project.should_not be_nil
      expect(project.dependencies.count).to > 5 
    end

  end

  describe 'fetch_project_file' do

    it 'returns new project_file fetched from GitHub' do
      user = UserFactory.create_new
      project = ProjectFactory.default user
      project.s3_filename = 'Gemfile'
      project.scm_fullname = 'reiz/test_gemi'
      project.scm_branch = 'master'

      pf = described_class.new.fetch_project_file project
      pf.should_not be_nil
      pf.match("source 'http://rubygems.org'")
    end

  end

end
