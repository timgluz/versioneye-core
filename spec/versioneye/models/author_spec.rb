require 'spec_helper'

describe Author do

  describe "save" do
    it "persists and updates name_id" do
      author = Author.new({ :name => "Hans Mueller", :email => "hans@heine.de" })
      author.update_name_id
      expect( author.save ).to be_truthy
      expect( author.name_id ).not_to be_nil
    end
  end

  describe "to_s" do
    it "returns the right value" do
      author = Author.new({ :name => "Hans Mueller", :email => "hans@heine.de" })
      author.update_name_id
      expect( author.save ).to be_truthy
      expect( author.to_s ).to eq('hans_mueller - hans@heine.de')
    end
  end

  describe "to_s" do
    it "returns the right value" do
      author = Author.new({ :name => "Hans Mueller", :email => "hans@heine.de" })
      author.update_name_id
      expect( author.save ).to be_truthy
      expect( author.to_param ).to eq('hans_mueller')
    end
  end

  describe "add_product" do
    it "adds a product" do
      author = Author.new({ :name => "Hans Mueller", :email => "hans@heine.de" })
      author.update_name_id
      expect( author.save ).to be_truthy
      expect( author.add_product( 'id', 'PHP', 'symfony/symfony' ) ).to be_truthy

      author = Author.first
      expect( author.products.first ).to eq('php::symfony/symfony')
      expect( author.products.count ).to eq(1)

      expect( author.add_product( 'id', 'PHP', 'symfony/symfony' ) ).to be_truthy

      author = Author.first
      expect( author.products.count ).to eq(1) # still one because unique
    end
  end

  describe "update_from" do
    it "updates from developer" do
      author = Author.new({ :name => "Hans Mueller", :email => "hans@heine.de" })
      author.update_name_id
      expect( author.save ).to be_truthy

      dev = Developer.new({ :name => "Max Krax", :email => 'max@google.de',
      :homepage => 'www.heise.de', :organization => 'heise', :organization_url => 'www.heise.de/orga',
      :role => 'CTO', :timezone => 'UTC' })

      author.update_from dev

      expect( author.name_id ).to eq('hans_mueller')
      expect( author.name ).to eq('Max Krax')
      expect( author.email ).to eq('max@google.de')
      expect( author.homepage ).to eq('www.heise.de')
      expect( author.organization ).to eq('heise')
      expect( author.organization_url ).to eq('www.heise.de/orga')
      expect( author.role ).to eq('CTO')
      expect( author.timezone ).to eq('UTC')
    end
  end

end
