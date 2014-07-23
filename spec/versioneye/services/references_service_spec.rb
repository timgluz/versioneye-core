require 'spec_helper'

describe ReferenceService do

  describe "find_by" do

    it "updates and finds reference" do
      product           = Product.new
      product.prod_key  = "junit/junit"
      product.name      = "junit"
      product.language  = Product::A_LANGUAGE_JAVA
      product.prod_type = Project::A_TYPE_MAVEN2
      product.save

      prod_1 = ProductFactory.create_new(1)
      prod_2 = ProductFactory.create_new(2)
      prod_3 = ProductFactory.create_new(3)
      prod_4 = ProductFactory.create_new(4)

      DependencyFactory.create_new(prod_1, product)
      DependencyFactory.create_new(prod_2, product)
      DependencyFactory.create_new(prod_3, product)
      DependencyFactory.create_new(prod_4, product)

      Dependency.count.should == 4

      ref = described_class.find_by product.language, product.prod_key
      ref.should_not be_nil
      ref.ref_count.should == 4
    end

  end

end
