require 'spec_helper'

describe MavenRepository do

  describe 'fill_it' do

    it 'fills the db with maven repos' do
      MavenRepository.count.should == 0
      MavenRepository.fill_it
      MavenRepository.count.should > 10
    end

  end

end
