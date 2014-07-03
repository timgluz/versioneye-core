require 'spec_helper'

describe Versionlink do

  describe 'as_json' do

    it 'returns nil because there is no product' do
      link = Versionlink.new({:language => Product::A_LANGUAGE_RUBY,
        :prod_key => "pdo", :link => "asas", :name => "pdo"})
      json = link.as_json nil
      json[:name].should eq("pdo")
      json[:link].should eq('asas')
    end

  end

  describe 'get_link' do

    it 'returns the http link' do
      link = Versionlink.new({:link => "www.heise.de"})
      link.get_link.should eq("http://www.heise.de")
    end

    it 'returns the link' do
      link = Versionlink.new({:link => "heise.de"})
      link.get_link.should eq("heise.de")
    end

  end

  describe 'find_version_link' do

    it 'returns 1 out of 2 versionlinks' do
      lang     = Product::A_LANGUAGE_RUBY
      url      = 'http://rails.com'
      prod_key = 'rails'
      version  = '3.0.0'

      link = Versionlink.new({:language => lang, :version_id => version,
        :prod_key => prod_key, :link => url, :name => prod_key})
      link.save.should be_truthy

      link2 = Versionlink.new({:language => lang, :version_id => version,
        :prod_key => prod_key, :link => "afaff", :name => prod_key})
      link2.save.should be_truthy

      links = Versionlink.find_version_link lang, prod_key, version, url
      links.should_not be_nil
      links.count.should == 1
      Versionlink.count.should == 2
    end

  end

  describe 'product' do

    it 'returns nil because there is no product' do
      link = Versionlink.new({:language => Product::A_LANGUAGE_RUBY,
        :prod_key => "pdo", :link => "asas", :name => "pdo"})
      link.product.should be_nil
    end

    it 'returns nil because there is no product' do
      product = ProductFactory.create_new
      product.save.should be_truthy
      link = Versionlink.new({:language => product.language,
        :prod_key => product.prod_key, :link => "asgas", :name => "name"})
      link.product.should_not be_nil
      link.product.prod_key.should eq(link.prod_key)
    end

  end

  describe 'remove_project_link' do

    it 'returns nil because link is nil' do
      Versionlink.remove_project_link( "", "", nil, false ).should be_nil
    end

    it 'returns nil because link is nil' do
      Versionlink.remove_project_link( "", "", "", false ).should be_nil
    end

    it 'returns true' do
      lang     = Product::A_LANGUAGE_RUBY
      url      = 'http://rails.com'
      prod_key = 'rails'
      link = Versionlink.new({:language => lang,
        :prod_key => prod_key, :link => url, :name => prod_key, :manual => true})
      link.save
      Versionlink.count.should == 1
      Versionlink.remove_project_link( lang, prod_key, url, true )
      Versionlink.count.should == 0
    end

    it 'returns false' do
      lang     = Product::A_LANGUAGE_RUBY
      url      = 'http://rails.com'
      prod_key = 'rails'
      link = Versionlink.new({:language => lang,
        :prod_key => prod_key, :link => url, :name => prod_key, :manual => false})
      link.save
      Versionlink.count.should == 1
      Versionlink.remove_project_link( lang, prod_key, url, true ).should == 0
      Versionlink.count.should == 1
    end

    it 'deletes 1 out of 2' do
      lang     = Product::A_LANGUAGE_RUBY
      url      = 'http://rails.com'
      prod_key = 'rails'
      link = Versionlink.new({:language => lang,
        :prod_key => prod_key, :link => url, :name => prod_key, :manual => false})
      link.save
      link2 = Versionlink.new({:language => lang,
        :prod_key => prod_key, :link => "afaa", :name => prod_key, :manual => false})
      link2.save
      Versionlink.count.should == 2
      Versionlink.remove_project_link( lang, prod_key, url, false ).should == 1
      Versionlink.count.should == 1
    end

  end

  describe "create_project_link" do

    it "creates returns an existing link" do
      url      = 'http://rails.com'
      prod_key = 'rails'
      Versionlink.count.should eq(0)
      link = Versionlink.new({:language => Product::A_LANGUAGE_RUBY, :prod_key => prod_key, :link => url, :name => prod_key})
      id   = link.id.to_s
      link.save.should be_truthy
      link_db = Versionlink.create_project_link Product::A_LANGUAGE_RUBY, prod_key, url, prod_key
      link_db.should_not be_nil
      link_db.id.to_s.should eq(id)
    end

    it "creates a new link" do
      url      = 'http://rails.com'
      prod_key = 'rails'
      Versionlink.count.should eq(0)
      link_db = Versionlink.create_project_link Product::A_LANGUAGE_RUBY, prod_key, url, prod_key
      link_db.should_not be_nil
      Versionlink.count.should eq(1)
    end

    it "creates a new link, because the existing link is a version specific link" do
      url      = 'http://rails.com'
      prod_key = 'rails'
      Versionlink.count.should eq(0)
      link = Versionlink.new({:language => Product::A_LANGUAGE_RUBY, :prod_key => prod_key, :version_id => '3.0.0', :link => url, :name => prod_key})
      link.save.should be_truthy
      id = link.id.to_s
      link_db = Versionlink.create_project_link Product::A_LANGUAGE_RUBY, prod_key, url, prod_key
      link_db.should_not be_nil
      link_db.id.to_s.should_not eq(id)
      Versionlink.count.should eq(2)
    end

  end

  describe 'create_versionlink' do

    it 'returns nil because link is nil' do
      Versionlink.create_versionlink("lang", "key", "version", nil, "name").should be_nil
    end

    it 'returns true' do
      Versionlink.create_versionlink("Ruby", "rails", "1.0.0", "http://rails.com", "Homepage").should be_truthy
    end

    it 'returns true and adds http to link' do
      Versionlink.create_versionlink("Ruby", "rails", "1.0.0", "rails.com", "Homepage").should be_truthy
      Versionlink.first.link.should eq("http://rails.com")
    end

    it 'returns nil because it exist already' do
      Versionlink.create_versionlink("Ruby", "rails", "1.0.0", "rails.com", "Homepage").should be_truthy
      Versionlink.count.should == 1
      Versionlink.create_versionlink("Ruby", "rails", "1.0.0", "rails.com", "Homepage").should be_nil
      Versionlink.count.should == 1
    end

  end

end
