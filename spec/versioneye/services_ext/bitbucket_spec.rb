require 'spec_helper'
require 'vcr'
require 'webmock/rspec'
require 'capybara/rspec'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes/'
  c.ignore_localhost = true
  c.hook_into :webmock
end

describe Bitbucket do

  include Capybara::DSL

  let(:user_with_token){create(:bitbucket_user,
    :bitbucket_token => Settings.instance.bitbucket_user_token,
    :bitbucket_secret => Settings.instance.bitbucket_user_secret,
    :bitbucket_login => Settings.instance.bitbucket_username)}


  # def connect_bitbucket(user)
  #   WebMock.allow_net_connect!
  #   Capybara.current_driver = Capybara.javascript_driver
  #   visit "/signin"
  #   click_button "Login with Bitbucket"

  #   #when bitbucket asks testuser's credentials
  #   within("form.login-form") do
  #     fill_in "Username", :with => Settings.instance.bitbucket_username
  #     fill_in 'Password', :with => Settings.instance.bitbucket_password
  #     click_button 'Log in'
  #   end
  #   #grant access
  #   if page.has_css? 'button.aui-button'
  #     click_button "Grant access"
  #   end

  #   user.reload
  # end


  it "returns content of the project files" do
    WebMock.allow_net_connect!

    username = user_with_token[:bitbucket_login]
    token    = user_with_token[:bitbucket_token]
    secret   = user_with_token[:bitbucket_secret]

    expect( username ).to_not be_nil
    expect( token    ).to_not be_nil
    expect( secret   ).to_not be_nil
    repo_name = "#{username}/fantom_hydra"

    VCR.use_cassette('bitbucket_project_file_from_branch', allow_playback_repeats: true) do
      file = Bitbucket.fetch_project_file_from_branch(repo_name, "master", "Gemfile", token, secret)
      expect( file               ).to_not be_nil
      expect( file.is_a?(String) ).to be_truthy
    end
  end


  context "as authorized user " do

    it "returns proper user info" do
      user_with_token.save

      expect( user_with_token[:bitbucket_token] ).to_not be_nil
      expect( user_with_token[:bitbucket_secret]).to_not be_nil

      VCR.use_cassette('bitbucket_user', allow_playback_repeats: true) do
        user_info = Bitbucket.user(user_with_token[:bitbucket_token],
                                   user_with_token[:bitbucket_secret])
        expect( user_info             ).to_not be_nil
        expect( user_info.is_a?(Hash) ).to be_truthy
        expect( user_info[:username]  ).to eql(user_with_token[:bitbucket_login])
      end
    end


    it "returns user information from API2" do
      username = user_with_token[:bitbucket_login]
      token    = user_with_token[:bitbucket_token]
      secret   = user_with_token[:bitbucket_secret]

      expect( username ).to_not be_nil
      expect( token    ).to_not be_nil
      expect( secret   ).to_not be_nil

      VCR.use_cassette('bitbucket_user_info', allow_playback_repeats: true) do
        user_info = Bitbucket.user_info(username, token, secret)
        expect( user_info             ).to_not be_nil
        expect( user_info.is_a?(Hash) ).to be_truthy
        expect( user_info[:username]  ).to eql(username)
      end
    end

    it "returns user organizations" do
      user_with_token[:bitbucket_token].should_not be_nil
      user_with_token[:bitbucket_secret].should_not be_nil

      VCR.use_cassette('bitbucket_user_orgs', allow_playback_repeats: true) do
        user_orgs = Bitbucket.user_orgs(user_with_token)
        expect( user_orgs              ).to_not be_nil
        expect( user_orgs.is_a?(Array) ).to be_truthy
      end
    end

    it "returns user repos" do
      username = user_with_token[:bitbucket_login]
      token    = user_with_token[:bitbucket_token]
      secret   = user_with_token[:bitbucket_secret]

      expect( username ).to_not be_nil
      expect( token    ).to_not be_nil
      expect( secret   ).to_not be_nil

      VCR.use_cassette('bitbucket_read_repos', allow_playback_repeats: true) do
        repos = Bitbucket.read_repos(username, token, secret)
        expect( repos              ).to_not be_nil
        expect( repos.is_a?(Array) ).to be_truthy
        expect( repos.size         ).to eql(1)
      end
    end

    it "returns information of the repo" do
      username = user_with_token[:bitbucket_login]
      token    = user_with_token[:bitbucket_token]
      secret   = user_with_token[:bitbucket_secret]

      expect( username ).to_not be_nil
      expect( token    ).to_not be_nil
      expect( secret   ).to_not be_nil

      VCR.use_cassette('bitbucket_repo_info', allow_playback_repeats: true) do
        repo = Bitbucket.repo_info("#{username}/fantom_hydra", token, secret)
        expect( repo             ).to_not be_nil
        expect( repo.is_a?(Hash) ).to be_truthy
        expect( repo[:name]      ).to eql("fantom_hydra")
      end
    end

    it "returns branches of the repo" do
      username = user_with_token[:bitbucket_login]
      token    = user_with_token[:bitbucket_token]
      secret   = user_with_token[:bitbucket_secret]

      expect( username ).to_not be_nil
      expect( token    ).to_not be_nil
      expect( secret   ).to_not be_nil

      repo_name = "#{username}/fantom_hydra"
      VCR.use_cassette('bitbucket_repo_branches', allow_playback_repeats: true) do
        branches = Bitbucket.repo_branches(repo_name, token, secret)
        expect( branches ).to_not be_nil
        expect( branches.is_a?(Array) ).to be_truthy
        expect( branches.size ).to eql(3)
        expect( branches.include? "java_branch"    ).to be_truthy
        expect( branches.include? "clojure_branch" ).to be_truthy
      end
    end


    it "returns correct hash-map of project files" do
      username = user_with_token[:bitbucket_login]
      token    = user_with_token[:bitbucket_token]
      secret   = user_with_token[:bitbucket_secret]

      expect( username ).to_not be_nil
      expect( token    ).to_not be_nil
      expect( secret   ).to_not be_nil

      repo_name = "#{username}/fantom_hydra"
      VCR.use_cassette('bitbucket_repo_project_files', allow_playback_repeats: false) do
        files = Bitbucket.repo_project_files(repo_name, token, secret)
        expect( files             ).to_not be_nil
        expect( files.is_a?(Hash) ).to be_truthy
        expect( files.keys.size   ).to eql(3)
        expect( files.keys.include?("java_branch") ).to be_truthy
        expect( files['java_branch'].is_a?(Array)  ).to be_truthy
        expect( files['java_branch'].size          ).to eql(1)
      end
    end

    it "returns a filetree of  the repo" do
      username = user_with_token[:bitbucket_login]
      token    = user_with_token[:bitbucket_token]
      secret   = user_with_token[:bitbucket_secret]

      expect( username ).to_not be_nil
      expect( token    ).to_not be_nil
      expect( secret   ).to_not be_nil

      repo_name = "#{username}/fantom_hydra"
      VCR.use_cassette('bitbucket_repo_branch_tree', allow_playback_repeats: false) do
        data = Bitbucket.repo_branch_tree(repo_name, "master", token, secret)
        expect( data                  ).to_not be_nil
        expect( data.has_key?(:files) ).to be_truthy

        files = data[:files]
        expect( files              ).to_not be_nil
        expect( files.is_a?(Array) ).to be_truthy
        expect( files.size         ).to eql(3)
      end
    end

    it "returns existing project files on the branch of the repo" do
      username = user_with_token[:bitbucket_login]
      token    = user_with_token[:bitbucket_token]
      secret   = user_with_token[:bitbucket_secret]

      expect( username ).to_not be_nil
      expect( token    ).to_not be_nil
      expect( secret   ).to_not be_nil

      repo_name = "#{username}/fantom_hydra"
      VCR.use_cassette('bitbucket_project_files_from_branch', allow_playback_repeats: false) do
        files = Bitbucket.project_files_from_branch(repo_name, "master", token, secret)
        expect( files               ).to_not be_nil
        expect( files.is_a?(Array)  ).to be_truthy
        expect( files.size          ).to eql(2)
        expect( files.first[:path]  ).to eql('Gemfile')
        expect( files.second[:path] ).to eql('bower.json')
      end
    end

  end
end
