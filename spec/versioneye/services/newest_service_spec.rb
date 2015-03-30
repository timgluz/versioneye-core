require 'spec_helper'

describe NewestService do

  describe "update_nil" do

    it "updates the nils" do
      product_1 = ProductFactory.create_new(36)
      product_2 = ProductFactory.create_new(37)

      dependency = Dependency.new({ :known => true, :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version, 
        :group_id => product_1.group_id, :artifact_id => product_1.artifact_id})
      dependency.save

      described_class.update_nils 

      dependency = Dependency.find dependency.id 
      dependency.current_version.should eq(product_1.version)
      dependency.outdated.should be_falsey 
    end

  end


  describe "post_process" do

    it "updates maven based product and dependency" do
      product_1 = ProductFactory.create_new(36)
      product_1.add_version "100000000"
      product_2 = ProductFactory.create_new(37)

      dependency = Dependency.new({ :known => true, :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version, 
        :current_version => product_1.version, 
        :group_id => product_1.group_id, :artifact_id => product_1.artifact_id})
      dependency.save

      newest = Newest.new({:language => product_1.language, :prod_key => product_1.prod_key, 
        :prod_type => product_1.prod_type, :version => '100000000' })
      newest.save 

      described_class.post_process

      product = Product.find product_1.id 
      product.version.should eq(newest.version)

      dep = Dependency.find dependency.id 
      dep.current_version.should eq(newest.version)
    end

    it 'updates a ruby product and dependency' do 
      product_1 = ProductFactory.create_for_gemfile('log4r', '1.0.0')
      product_1.save 
      product_2 = ProductFactory.create_for_gemfile('bundler', '1.0.0')
      product_2.save 

      dependency = Dependency.new({ :known => true, :language => product_2.language,
        :prod_key => product_2.prod_key, :prod_version => product_2.version,
        :dep_prod_key => product_1.prod_key, :version => product_1.version, 
        :current_version => product_1.version, 
        :group_id => product_1.group_id, :artifact_id => product_1.artifact_id})
      dependency.save

      newest = Newest.new({:language => product_1.language, :prod_key => product_1.prod_key, 
        :prod_type => product_1.prod_type, :version => '2.0.0' })
      newest.save 

      product_1.add_version '2.0.0'
      product_1.save 

      described_class.post_process

      product = Product.find product_1.id 
      product.version.should eq(newest.version)

      dep = Dependency.find dependency.id 
      dep.current_version.should eq(newest.version)
    end

  end

end
