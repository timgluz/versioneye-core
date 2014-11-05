require 'spec_helper'
require 'vcr'
require 'webmock'

require 'capybara/rspec'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes/'
  c.ignore_localhost = true
  c.hook_into :webmock
end

describe MeClient do

  describe "fetch me" do

    it "fetches the me json" do
      VCR.use_cassette('versioneye_api_v2_me', allow_playback_repeats: true) do
        resp =  MeClient.show "hasgagagasgfsa"
        resp.should_not be_nil
      end
    end

  end

end
