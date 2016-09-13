require 'spec_helper'

describe Api do

  describe "create_new" do

    it "creates a new api" do
      user = UserFactory.create_new
      api = Api.create_new(user)
      expect( api ).to_not be_nil
      expect( api.user_id ).to eq(user.id.to_s)
      expect( api.api_key ).to_not be_nil
    end

    it "creates a new api instance with higher rate limit" do
      Plan.create_defaults
      user = UserFactory.create_new
      expect( user.save ).to be_truthy
      api = Api.create_new(user)
      expect( api ).to_not be_nil
      expect( api.user_id ).to eq(user.id.to_s)
      expect( api.user ).to_not be_nil
      expect( api.api_key ).to_not be_nil
      expect( api.rate_limit ).to eq(50)
    end

  end

  describe "create_new_for_orga" do

    it "creates a new api for orga" do
      orga = Organisation.new({:name => "test_orga"})
      api = Api.create_new_for_orga(orga)
      expect( api ).to_not be_nil
      expect( api.user_id ).to be_nil
      expect( api.organisation_id ).to eq(orga.ids)
      expect( api.api_key ).to_not be_nil
    end

    it "creates a new api instance with higher rate limit" do
      Plan.create_defaults
      medium_plan = Plan.medium
      orga = Organisation.new({:name => "test_orga"})
      orga.plan = medium_plan
      expect( orga.save ).to be_truthy
      api = Api.create_new_for_orga(orga)
      expect( api ).to_not be_nil
      expect( api.user_id ).to be_nil
      expect( api.organisation_id ).to eq(orga.ids)
      expect( api.organisation ).to_not be_nil
      expect( api.api_key ).to_not be_nil
      expect( api.rate_limit ).to eq(medium_plan.api_rate_limit)
      expect( api.rate_limit ).to_not eq(50)
    end

  end

  describe "generate_api_key" do

    it "creates a new api" do
      user = UserFactory.create_new
      api = Api.create_new(user)
      old_key = api.api_key
      api.generate_api_key!
      expect( api.api_key ).to_not eq( old_key )
    end

  end

  describe "by_user" do

    it "creates a new api" do
      user = UserFactory.create_new
      api = Api.create_new(user)
      api_db = Api.by_user( user )
      expect( api.ids ).to eq( api_db.ids )
    end

  end

  describe "user" do

    it "creates a new api" do
      user = UserFactory.create_new
      api = Api.create_new(user)
      u = api.user
      expect( user.ids ).to eq( u.ids )
    end

  end


end
