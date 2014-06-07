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

end
