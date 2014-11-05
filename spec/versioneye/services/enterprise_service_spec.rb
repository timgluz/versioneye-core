require 'spec_helper'
require 'vcr'
require 'webmock'

require 'capybara/rspec'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes/'
  c.ignore_localhost = true
  c.hook_into :webmock
end

describe EnterpriseService do

  describe 'activated?' do
    before :each do
      Settings.instance.instance_variable_set(:@environment, 'enterprise')
    end
    after :each do
      Settings.instance.instance_variable_set(:@environment, 'test')
    end
    it 'returns false' do
      EnterpriseService.activated?().should be_falsey
    end
    it 'returns false because project count is missing' do
      env        = Settings.instance.environment
      GlobalSetting.set env, 'API_KEY', 'asgasfasfgs'
      EnterpriseService.activated?().should be_falsey
    end
    it 'returns false because API_KEY is missing' do
      env        = Settings.instance.environment
      GlobalSetting.set env, 'E_PROJECTS', '8'
      EnterpriseService.activated?().should be_falsey
    end
    it 'returns true' do
      env        = Settings.instance.environment
      GlobalSetting.set env, 'API_KEY', 'asgasfasfgs'
      GlobalSetting.set env, 'E_PROJECTS', '8'
      EnterpriseService.activated?().should be_truthy
    end
    it 'returns false' do
      env        = Settings.instance.environment
      GlobalSetting.set env, 'API_KEY', 'asgasfasfgs'
      GlobalSetting.set env, 'E_PROJECTS', '0'
      EnterpriseService.activated?().should be_falsey
    end
    it 'returns true' do
      Settings.instance.environment = 'production'
      EnterpriseService.activated?().should be_truthy
    end
  end

  describe 'activate!' do
    before :each do
      Settings.instance.environment = 'enterprise'
    end
    it 'returns true' do
      VCR.use_cassette('enterprise_activate_1', allow_playback_repeats: true) do
        env = Settings.instance.environment
        api_key = "fanzy_nanzy_api_key_fanzy"
        GlobalSetting.get( env, 'API_KEY' ).should be_nil
        EnterpriseService.activate!( api_key ).should be_truthy
        GlobalSetting.get( env, 'API_KEY' ).should_not be_nil
        GlobalSetting.get( env, 'API_KEY' ).should eq( api_key )
      end
    end
  end

end
