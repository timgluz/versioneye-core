require 'spec_helper'

describe Api do

  describe "create_new" do

    it "creates a new api" do
      user = User.new
      api = Api.create_new(user)
      api.should_not be_nil
      api.user_id.should eq(user.id.to_s)
      api.api_key.should_not be_nil
    end

  end

end
