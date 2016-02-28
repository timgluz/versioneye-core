require 'spec_helper'
require 'vcr'
require 'webmock'

describe GitReposImportWorker do

  describe 'work' do

    it 'fetches repos from GitHub' do

      user = UserFactory.create_new
      user.github_id = '10449954'
      user.github_token = '07d9d399f1a8ff3380a9eb8'
      user.github_login = 'veye1test'
      user.github_scope = 'public_repo,user:email'
      expect( user.save ).to be_truthy
      expect( user.github_repos ).to be_empty
      expect( GithubRepo.count ).to eq(0)

      VCR.use_cassette('git_repos_import_worker_github', allow_playback_repeats: true) do
        worker = Thread.new{ described_class.new.work }
        user_id = user.ids
        GitReposImportProducer.new("github:::#{user_id}")
        sleep 3
        worker.exit
      end

      expect( GithubRepo.count ).to_not eq(0)
      user.reload
      expect( user.github_repos ).to_not be_empty
    end

  end


end
