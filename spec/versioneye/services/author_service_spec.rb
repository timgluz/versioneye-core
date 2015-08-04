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

end
