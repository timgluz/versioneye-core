require 'spec_helper'
require 'vcr'
require 'webmock'

describe GitRepoImportWorker do

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

      VCR.use_cassette('git_repo_import_worker_github', allow_playback_repeats: true) do
        worker1 = Thread.new{ GitReposImportWorker.new.work }
        worker2 = Thread.new{ GitRepoImportWorker.new.work }

        expect( GithubRepo.count ).to eq(0)
        user_id = user.ids
        GitReposImportProducer.new("github:::#{user_id}")
        sleep 3
        expect( GithubRepo.count ).to_not eq(0)

        git_repo = GithubRepo.by_fullname("veye1test/docker_web_ui").first
        expect( git_repo.branches ).to be_nil

        repo_id = git_repo.ids
        GitRepoImportProducer.new("github:::#{user_id}:::#{repo_id}")
        sleep 3

        git_repo.reload
        expect( git_repo.branches ).to_not be_empty
        expect( git_repo.project_files ).to_not be_empty

        worker1.exit
        worker2.exit
      end
    end

  end

end
