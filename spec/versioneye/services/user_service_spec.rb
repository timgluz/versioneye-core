require 'spec_helper'

describe UserService do


  describe 'valid_user?' do

    it 'returns false because email not valid' do
      user = User.new({:email => ''})
      expect( UserService.valid_user?(user, {}) ).to be_falsey
    end

    it 'returns false because fullname is not valid' do
      user = User.new({:email => 'valid@email.de'})
      expect( UserService.valid_user?(user, {}) ).to be_falsey
    end

    it 'returns false because no password' do
      user = User.new({:email => 'valid@email.de', :fullname => "full name"})
      expect( UserService.valid_user?(user, {}) ).to be_falsey
    end

    it 'returns false because no terms' do
      user = User.new({:email => 'valid@email.de', :fullname => "full name", :password => 'my_super_secret'})
      expect( UserService.valid_user?(user, {}) ).to be_falsey
    end

    it 'returns true because user is valid' do
      user = User.new({:email => 'valid@email.de', :fullname => "full name", :password => 'my_super_secret', :terms => true})
      expect( UserService.valid_user?(user, {}) ).to be_truthy
    end

  end


  describe 'all_users_paged' do

    it 'iterates over all users' do
      user1 = UserFactory.create_new "hans"
      user2 = UserFactory.create_new "tanz"
      UserService.all_users_paged do |users|
        expect( users.count ).to eq(2)
      end
    end

  end


  describe "delete" do

    let(:user)   { UserFactory.create_new(34) }

    it "deletes the user in the right way" do
      ActionMailer::Base.deliveries.clear
      email = String.new( user.email )
      username = String.new( user.username )
      user.email.should_not be_nil
      user.username.should_not be_nil
      user.fullname.should_not be_nil
      user.github_id = "123"
      user.github_token = "asgasgas"
      user.github_scope = "none"
      user.bitbucket_id = "456"
      user.bitbucket_token = "asgfasgfa"
      user.bitbucket_secret = "asgasgasgas"
      user.save.should be_truthy
      UserEmail.new({:email => "afa@bafa.de", :user_id => user.id.to_s}).save
      user.emails.count.should eq(1)
      Notification.count.should eql(0)
      NotificationFactory.create_new user, true
      Notification.count.should eql(1)
      UserService.delete(user).should be_truthy
      Notification.count.should eql(0)
      user.emails.count.should eq(0)
      user.fullname.should eql("Deleted")
      user.email.should_not eql(email)
      user.username.should_not eql(username)
      user.github_id.should be_nil
      user.github_token.should be_nil
      user.github_scope.should be_nil
      user.bitbucket_id.should be_nil
      user.bitbucket_token.should be_nil
      user.bitbucket_secret.should be_nil
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

  describe "active_users" do

    before(:each) do
      User.destroy_all
      @user = User.new
      @user.fullname = "Hans Tanz"
      @user.username = "hans_tanz"
      @user.email = "hans@tanz.de"
      @user.password = "password"
      @user.salt = "salt"
      @user.github_id = "github_id_123"
      @user.terms = true
      @user.datenerhebung = true
      @user.save
      UserFactory.create_defaults
    end

    it "returns 3mpty list, when there's no active users" do
      UserService.active_users.count.should eql(0)
    end

    it "returns one user, when there's only one user following" do
      user = User.all.first
      prod = ProductFactory.create_new
      user.products.push prod
      UserService.active_users.count.should eql(1)
    end

    it "returns one user, when there's only one user who have add comment" do
      user = User.all.first
      Versioncomment.new(user_id: user.id, product_key: "1", version: "1", comment: "1").save
      Versioncomment.new(user_id: user.id, product_key: "2", version: "2", comment: "2").save
      UserService.active_users.count.should eql(1)
    end

    it "returns only one user, when there's only one user with active project" do
      user                = User.all.first
      project             = Project.new
      project.user        = user
      project.name        = "test"
      project.save
      UserService.active_users.count.should eql(1)
      Project.delete_all
    end

    it "returns only one user, even she commented and has active project" do
      user = User.all.first
      Project.new(user_id: user.id)
      Versioncomment.new(user_id: user.id, product_key: "1", version: "1", comment: "1").save
      UserService.active_users.count.should eql(1)
      Project.delete_all
      Versioncomment.delete_all
    end

    it "returns 2 user, when she commented and he has active project" do
      expect( User.count ).to eq(6)
      expect( UserService.active_users.count ).to eql(0)
      she                 = User.all.first
      he                  = User.all[4]
      project             = Project.new
      project.user        = she
      project.name        = "test"
      expect( project.save ).to be_truthy
      expect( Versioncomment.new(user_id: he.id, product_key: "1", version: "1", comment: "1").save ).to be_truthy
      expect( UserService.active_users.count ).to eql(2)
      Project.delete_all
      Versioncomment.delete_all
    end

  end

  describe "reset_password" do

    let(:github_user) { FactoryGirl.create(:github_user)}

    it "does reset the password" do
      ActionMailer::Base.deliveries.clear
      password = String.new github_user.password
      user = User.authenticate(github_user.email, password)
      user.should_not be_nil
      UserService.reset_password( user )
      user.password.should_not eql(password)
      user.verification.should_not be_nil
      ActionMailer::Base.deliveries.size.should == 1
    end

  end

  describe 'update_languages' do

    it 'updates the users languages' do
      user = UserFactory.create_new
      user.languages.should be_nil
      User.count.should == 1
      UserService.update_languages
      user.reload
      user.languages.should be_nil

      product = ProductFactory.create_new 24
      ProductService.follow product.language, product.prod_key, user
      UserService.update_languages
      user.reload
      user.languages.should_not be_nil

      ProductService.unfollow product.language, product.prod_key, user
      UserService.update_languages
      user.reload
      user.languages.should be_nil
    end

  end

end
