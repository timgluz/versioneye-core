require 'spec_helper'

describe EnterpriseService do

  describe 'activated?' do
    before :each do
      Settings.instance.environment = 'enterprise'
    end
    it 'returns false' do
      EnterpriseService.activated?().should be_falsey
    end
    it 'returns false because project count is missing' do
      env        = Settings.instance.environment
      GlobalSetting.set env, 'API-KEY', 'asgasfasfgs'
      EnterpriseService.activated?().should be_falsey
    end
    it 'returns false because API-KEY is missing' do
      env        = Settings.instance.environment
      GlobalSetting.set env, 'E-PROJECTS', '8'
      EnterpriseService.activated?().should be_falsey
    end
    it 'returns true' do
      env        = Settings.instance.environment
      GlobalSetting.set env, 'API-KEY', 'asgasfasfgs'
      GlobalSetting.set env, 'E-PROJECTS', '8'
      EnterpriseService.activated?().should be_truthy
    end
    it 'returns false' do
      env        = Settings.instance.environment
      GlobalSetting.set env, 'API-KEY', 'asgasfasfgs'
      GlobalSetting.set env, 'E-PROJECTS', '0'
      EnterpriseService.activated?().should be_falsey
    end
    it 'returns true' do
      Settings.instance.environment = 'production'
      EnterpriseService.activated?().should be_truthy
    end
  end

end
