require 'spec_helper'

describe AuthorService do

  describe "fetch_author" do

    it "fetches the author by email" do
      author = Author.new({:name_id => "test", :name => "test", :email => 'test@web.de'})
      expect( author.save ).to be_truthy

      dev  = Developer.new({:email => 'test@web.de'})
      auth = AuthorService.fetch_author(dev)
      expect( auth ).to_not be_nil
    end

    it "fetches the author by emails" do
      author = Author.new({:name_id => "test", :name => "test"})
      author.emails << "test@web.de"
      author.email = nil
      expect( author.save ).to be_truthy

      dev  = Developer.new({:email => 'test@web.de'})
      auth = AuthorService.fetch_author(dev)
      expect( auth ).to_not be_nil
    end

    it "fetches the author by name" do
      author = Author.new({:name_id => "test", :name => "test"})
      expect( author.save ).to be_truthy

      dev  = Developer.new({:name => 'test'})
      auth = AuthorService.fetch_author(dev)
      expect( auth ).to_not be_nil
      expect( auth.ids ).to eq(author.ids)
    end

    it "fetche a new author by name" do
      dev  = Developer.new({:name => 'test'})
      auth = AuthorService.fetch_author(dev)
      expect( auth ).to_not be_nil
      expect( auth.name_id ).to eq('test')
      expect( auth.name ).to eq('test')
    end

  end

  describe "dev_to_author" do

    it "doesnt convert because dev has no product" do
      dev = Developer.new({:name => 'test', :email => 'test@web.de'})
      expect( AuthorService.dev_to_author(dev) ).to be_nil
    end

    it "doesnt convert because dev has no name and email not exist in author collection" do
      product = ProductFactory.create_new
      dev = Developer.new({:email => 'test@web.de', :language => product.language, :prod_key => product.prod_key, :version => product.version})
      expect( AuthorService.dev_to_author(dev) ).to be_nil
    end

    it "converts because it creates a new author" do
      expect( Author.count ).to be(0)
      product = ProductFactory.create_new
      dev = Developer.new({:name => 'test', :email => 'test@web.de', :language => product.language, :prod_key => product.prod_key, :version => product.version})
      author = AuthorService.dev_to_author(dev)
      expect( author ).to_not be_nil
      expect( author.name ).to eq('test')
      expect( author.name_id ).to eq('test')
      expect( Author.count ).to be(1)
    end

    it "converts - it finds author by name" do
      author = Author.new({:name_id => "test", :name => "test"})
      expect( author.save ).to be_truthy
      expect( Author.count ).to be(1)

      product = ProductFactory.create_new
      dev = Developer.new({:name => 'test', :email => 'test@web.de', :language => product.language, :prod_key => product.prod_key, :version => product.version})
      expect( AuthorService.dev_to_author(dev) ).to_not be_nil
      expect( Author.count ).to be(1)
    end

    it "converts - it finds author by email" do
      author = Author.new({:name_id => "test", :name => "test", :email => 'test@web.de'})
      expect( author.save ).to be_truthy
      expect( Author.count ).to be(1)

      product = ProductFactory.create_new
      dev = Developer.new({:email => 'test@web.de', :language => product.language, :prod_key => product.prod_key, :version => product.version})
      expect( AuthorService.dev_to_author(dev) ).to_not be_nil
      expect( Author.count ).to be(1)
    end

  end

  describe "update_authors" do

    it "updates the authors" do
      expect( Author.count ).to be(0)

      product = ProductFactory.create_new
      dev = Developer.new({:name => "hans", :email => 'test@web.de', :language => product.language, :prod_key => product.prod_key, :version => product.version})
      expect( dev.save ).to be_truthy

      AuthorService.update_authors product.language
      expect( Author.count ).to be(1)
    end

  end


  describe "update_maintainers" do

    it "updates the maintainers" do
      user = UserFactory.create_new
      user.email = "test@web.de"
      expect( user.save ).to be_truthy
      expect( user.maintainer ).to be_nil

      product = ProductFactory.create_new
      dev = Developer.new({:name => "hans", :email => 'test@web.de', :language => product.language, :prod_key => product.prod_key, :version => product.version})
      expect( dev.save ).to be_truthy

      AuthorService.update_authors product.language
      expect( Author.count ).to be(1)

      AuthorService.update_maintainers
      user = User.first
      expect( user.maintainer ).to_not be_nil
      expect( user.maintainer ).to_not be_empty

      key = "#{product.language}::#{product.prod_key}".downcase
      expect( user.maintainer.include?( key ) ).to be_truthy
    end

  end


  describe "invite_users_to_edit" do

    it "invites a user to edit" do
      user = UserFactory.create_new
      user.email = "test@web.de"
      expect( user.save ).to be_truthy
      expect( user.maintainer ).to be_nil

      product = ProductFactory.create_new
      dev = Developer.new({:name => "hans", :email => 'test@web.de', :language => product.language, :prod_key => product.prod_key, :version => product.version})
      expect( dev.save ).to be_truthy

      AuthorService.update_authors product.language
      expect( Author.count ).to be(1)

      AuthorService.update_maintainers

      ActionMailer::Base.deliveries.clear
      ActionMailer::Base.deliveries.size.should == 0

      AuthorService.invite_users_to_edit

      ActionMailer::Base.deliveries.size.should == 1
    end

  end


end
