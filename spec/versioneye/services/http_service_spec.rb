require 'spec_helper'

describe HttpService do

  describe 'fetch_response' do

    it 'returns nil for nil' do
      described_class.fetch_response(nil).should be_nil
    end

    it 'returns not nil for for valid url' do
      described_class.fetch_response("https://s3.amazonaws.com/veye_test_env/Gemfile").should_not be_nil
    end

  end

end
