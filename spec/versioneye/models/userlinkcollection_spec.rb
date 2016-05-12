require 'spec_helper'

describe Userlinkcollection do

  let(:link) { Userlinkcollection.new }


  describe 'find_all_by_user' do

    it 'find_all_by_user' do
      user = UserFactory.create_new
      expect( user.save ).to be_truthy
      link.user_id = user.ids
      expect(link.save).to be_truthy
      ulc = Userlinkcollection.find_all_by_user(user.ids)
      expect( ulc ).to_not be_nil
    end

  end

  describe 'empty?' do

    it 'it is empty ' do
      link.empty?().should be_truthy
    end

    it 'it is not empty ' do
      link.github = "https://github.com/reiz"
      link.empty?().should be_falsey
    end

  end

  describe 'github_empty?' do

    it 'github is empty ' do
      link.github_empty?().should be_truthy
    end

    it 'github is empty ' do
      link.github = ""
      link.github_empty?().should be_truthy
    end

    it 'github is empty ' do
      link.github = nil
      link.github_empty?().should be_truthy
    end

    it 'github is not empty ' do
      link.github = "https://github.com/reiz"
      link.github_empty?().should be_falsey
    end

  end

  describe 'linkedin_url' do

    it 'returns linkedin URL' do
      link.linkedin = 'linked.in/user'
      expect( link.linkedin_url ).to eq('http://linked.in/user')
    end

  end

  describe 'xing_url' do

    it 'returns XING URL' do
      link.xing = 'xing.com/user'
      expect( link.xing_url ).to eq('http://xing.com/user')
    end

  end

  describe 'github_url' do

    it 'returns GitHub URL' do
      link.github = 'github.com/user'
      expect( link.github_url ).to eq('https://github.com/user')
    end

  end

  describe 'stackoverflow_url' do

    it 'returns Stackoverflow URL' do
      link.stackoverflow = 'stack.com/user'
      expect( link.stackoverflow_url ).to eq('http://stack.com/user')
    end

  end

  describe 'twitter_url' do

    it 'returns Twitter URL' do
      link.twitter = 'twitter.com/user'
      expect( link.twitter_url ).to eq('https://twitter.com/user')
    end

  end

  describe 'facebook_url' do

    it 'returns Facebook URL' do
      link.facebook = 'facebook.com/user'
      expect( link.facebook_url ).to eq('https://facebook.com/user')
    end

  end

end
