require 'spec_helper'

describe ApiCall do

  describe "user" do

    it "returns the user" do
      user = UserFactory.create_new
      api = Api.create_new(user)

      call = ApiCall.new({ :user_id => user.ids })

      expect( call.user.ids ).to eq(user.ids)
    end

  end

  describe "project" do

    it "returns the project" do
      user = UserFactory.create_new
      project = ProjectFactory.create_new user
      api = Api.create_new(user)

      call = ApiCall.new({ :user_id => user.ids, :project_id => project.ids })

      expect( call.project.ids ).to eq(project.ids)
    end

  end


end
