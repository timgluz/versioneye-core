require 'spec_helper'

describe Repository do

  describe 'as_json' do

    it 'returns the json' do
      repo = Repository.new({:src => 'http://heise.de', :repotype => 'maven'})
      json = repo.as_json
      json.should_not be_nil
      json[:repo_source].should eq("http://heise.de")
      json[:repo_type].should eq("maven")
    end

  end

  describe 'to_s' do

    it 'the src' do
      repo = Repository.new({:src => 'http://heise.de', :repotype => 'maven'})
      repo.to_s.should eq('http://heise.de')
    end

  end

  describe 'name_for' do

    it 'returns Bintray JCenter' do
      expect( Repository.name_for("http://jcenter.bintray.com/") ).to eq('Bintray JCenter')
    end
    it 'returns Apache' do
      expect( Repository.name_for("http://repo.maven.apache.org/maven2") ).to eq('Apache')
    end
    it 'returns Clojars' do
      expect( Repository.name_for("http://clojars.org/repo/") ).to eq('Clojars')
    end
    it 'returns RubyGems' do
      expect( Repository.name_for("https://rubygems.org/") ).to eq('RubyGems')
    end
    it 'returns the src because there is no mapping' do
      expect( Repository.name_for("https://not_mapped.org/") ).to eq('https://not_mapped.org/')
    end
    it 'returns nil because empty string' do
      expect( Repository.name_for(" ") ).to be_nil
    end

  end

end
