require 'spec_helper'

describe UpdateStrategy do

  describe 'updater_for' do

    it 'returns the URL Updater' do
      updater = UpdateStrategy.updater_for Project::A_SOURCE_URL
      updater.instance_of?(UrlUpdater).should be_true
    end
    it 'returns the Upload Updater' do
      updater = UpdateStrategy.updater_for Project::A_SOURCE_UPLOAD
      updater.instance_of?(UploadUpdater).should be_true
    end
    it 'returns the GitHub Updater' do
      updater = UpdateStrategy.updater_for Project::A_SOURCE_GITHUB
      updater.instance_of?(GithubUpdater).should be_true
    end
    it 'returns the Bitbucket Updater' do
      updater = UpdateStrategy.updater_for Project::A_SOURCE_BITBUCKET
      updater.instance_of?(BitbucketUpdater).should be_true
    end

  end

end
