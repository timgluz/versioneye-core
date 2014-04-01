require 'spec_helper'

describe SubmittedUrl do

  describe 'find_by_id' do
    before(:each) do
      @submitted_url = SubmittedUrlFactory.create_new
    end

    it 'return nil, when parameter `id` is nil' do
      SubmittedUrl.find_by_id(nil).should be_nil
    end

    it 'return nil, when given id dont exist' do
      SubmittedUrl.find_by_id("cibberish-cabberish-bingo-mongo-kongo").should be_nil
    end

    it 'returns object with same id, when given ID exists in db'  do
      @submitted_url.reload
      result = SubmittedUrl.find_by_id(@submitted_url._id)
      result.should_not be_nil
      result._id.to_s.should eql(@submitted_url._id.to_s)
      result.to_s.should eq( "<SubmittedUrl> url: #{@submitted_url.url}, declined: #{@submitted_url.declined}, integrated: #{@submitted_url.integrated}, product_resource: #{@submitted_url.product_resource_id.to_s}" )
    end
  end

  describe 'user' do
      before(:each) do
        @url_without_userid = SubmittedUrlFactory.create_new
        @test_user          = UserFactory.create_new(2)
        @url_with_userid    = SubmittedUrlFactory.create_new(user_id: @test_user._id)
      end

      after(:each) do
        @url_without_userid.delete
        @test_user.delete
        @url_with_userid.delete
      end

      it 'returns nil, submittedUrl dont have user information' do
        @url_without_userid.user.should be_nil
      end

      it 'returns correct User when user_id exists' do
        user = @url_with_userid.user
        user.should_not be_nil
        user._id.to_s.should eql(@test_user._id.to_s)
      end
  end

  describe 'type_guessed' do

    it 'returns GitHub' do
      su = SubmittedUrl.new({ :url => 'https://github.com' })
      su.type_guessed.should eq('GitHub')
    end

    it 'returns an empty string' do
      su = SubmittedUrl.new({ :url => 'https://bonzo.com' })
      su.type_guessed.should eq('')
    end

  end

  describe 'url_guessed' do

    it 'returns the API GitHub repo url' do
      su = SubmittedUrl.new({ :url => 'https://github.com/versioneye/versioneye_maven_plugin' })
      su.url_guessed.should eq('https://api.github.com/repos/versioneye/versioneye_maven_plugin')
    end

    it 'returns the given URL' do
      su = SubmittedUrl.new({ :url => 'https://bonzo.com' })
      su.url_guessed.should eq('https://bonzo.com')
    end

  end

  describe 'name_guessed' do

    it 'returns the GitHub repo name' do
      su = SubmittedUrl.new({ :url => 'https://github.com/versioneye/versioneye_maven_plugin' })
      su.name_guessed.should eq('versioneye/versioneye_maven_plugin')
    end

    it 'returns the given URL' do
      su = SubmittedUrl.new({ :url => 'https://bonzo.com' })
      su.name_guessed.should eq('https://bonzo.com')
    end

  end

end
