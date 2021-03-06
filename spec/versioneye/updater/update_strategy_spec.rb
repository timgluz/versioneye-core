require 'spec_helper'

describe UpdateStrategy do

  describe 'updater_for' do

    it 'returns the URL Updater' do
      updater = UpdateStrategy.updater_for Project::A_SOURCE_URL
      updater.instance_of?(UrlUpdater).should be_truthy
    end

    it 'returns the Upload Updater' do
      updater = UpdateStrategy.updater_for Project::A_SOURCE_API
      updater.instance_of?(UploadUpdater).should be_truthy
    end

    it 'returns the Upload Updater' do
      updater = UpdateStrategy.updater_for 'nil'
      updater.instance_of?(UploadUpdater).should be_truthy
    end

    it 'returns the Upload Updater' do
      updater = UpdateStrategy.updater_for Project::A_SOURCE_UPLOAD
      updater.instance_of?(UploadUpdater).should be_truthy
    end

    it 'returns the GitHub Updater' do
      updater = UpdateStrategy.updater_for Project::A_SOURCE_GITHUB
      updater.instance_of?(GithubUpdater).should be_truthy
    end

    it 'returns the Bitbucket Updater' do
      updater = UpdateStrategy.updater_for Project::A_SOURCE_BITBUCKET
      updater.instance_of?(BitbucketUpdater).should be_truthy
    end

    it 'returns the Stash Updater' do
      updater = UpdateStrategy.updater_for Project::A_SOURCE_STASH
      updater.instance_of?(StashUpdater).should be_truthy
    end

  end

end
