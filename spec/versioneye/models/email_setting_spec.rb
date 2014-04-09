require 'spec_helper'

describe EmailSetting do

  describe "defaults" do

    it "checks the default values" do
      es = EmailSetting.new
      es.address.should_not be_nil
      es.port.should_not be_nil
      es.username.should_not be_nil
      es.password.should_not be_nil
      es.domain.should_not be_nil
      es.authentication.should_not be_nil
      es.enable_starttls_auto.should_not be_nil
      es.save.should be_true
    end

  end

end
