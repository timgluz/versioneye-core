require 'spec_helper'

describe Reference do

  describe 'Add products' do

    it 'adds 2 products' do
      prod_1 = ProductFactory.create_new 1
      prod_2 = ProductFactory.create_new 2
      prod_1.save
      prod_2.save

      prod_keys = []
      prod_keys << prod_1.prod_key
      prod_keys << prod_2.prod_key

      Product.count.should eq(2)

      ref = Reference.new
      ref.language = prod_1.language
      ref.update_from prod_keys
      ref.ref_count.should eq(2)
      ref.prod_keys.should_not be_empty
      ref.save.should be_truthy
      products = ref.products 1
      products.count.should eq(2)
    end

  end

end
