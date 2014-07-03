require 'spec_helper'

describe EmailSetting do

  describe "create_default" do

    it "checks the default values" do
      EmailSetting.create_default.should be_truthy
      es = EmailSetting.first
      es.address.should_not be_nil
      es.port.should_not be_nil
      es.username.should_not be_nil
      es.password.should_not be_nil
      es.domain.should_not be_nil
      es.authentication.should_not be_nil
      es.enable_starttls_auto.should_not be_nil
      es.sender_email.should_not be_nil
      es.save.should be_truthy
    end

  end

end
