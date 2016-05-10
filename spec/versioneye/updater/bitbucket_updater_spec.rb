require 'spec_helper'

describe BitbucketUpdater do

  describe 'update' do

    it 'returns nil' do
      user = UserFactory.create_new
      project = ProjectFactory.default user

      new_project = described_class.new.update project
      expect( new_project ).to be_nil
    end

    it 'returns the updated project' do
      user = UserFactory.create_new
      user.save
      project = ProjectFactory.default user
      project.s3_filename = 'Gemfile'
      project.scm_fullname = 'reiz/test_gemi'
      project.scm_branch = 'master'
      expect( project.save ).to be_truthy
      id = project.ids

      described_class.new.update project
      project = Project.find id
      expect( project ).to_not be_nil
      expect( project.parsing_errors.count ).to eq(0)
      expect(project.dependencies).to_not be_empty
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
      expect( pf ).to_not be_nil
      pf.match("source 'http://rubygems.org'")
    end

  end

end
