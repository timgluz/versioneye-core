require 'spec_helper'

describe Project do

  before(:each) do
    user        = UserFactory.create_new
    @product    = ProductFactory.create_new(1, :maven, true, "2.0.0")
    @project    = ProjectFactory.create_new( user )
  end

end
