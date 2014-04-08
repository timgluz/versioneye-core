require 'spec_helper'

describe CircleElementService do


  describe 'dependency_circle' do

    it 'returns an empty hash' do
      resp = CircleElementService.dependency_circle nil, nil, nil, nil
      resp.should_not be_nil
      resp.should be_empty
    end

    it 'returns an empty hash because product doesnt has dependencies' do
      prod = ProductFactory.create_new 1
      resp = CircleElementService.dependency_circle prod.language, prod.prod_key, prod.version, nil
      resp.should_not be_nil
      resp.should be_empty
    end

    it 'returns an empty hash because product doesnt has dependencies' do
      prod_1 = ProductFactory.create_new 1
      prod_2 = ProductFactory.create_new 2
      dep = DependencyFactory.create_new prod_1, prod_2
      resp = CircleElementService.dependency_circle prod_1.language, prod_1.prod_key, prod_1.version, nil
      resp.should_not be_nil
      resp.should_not be_empty
      resp[prod_2.prod_key].should_not be_nil
    end

  end


  describe "attach_label_to_element" do

    it "attaches the label to the element" do
      dependency = Dependency.new
      dependency.name = "junit"
      dependency.version = "1.0.1"
      element = CircleElement.new
      CircleElementService.send( :public, *CircleElementService.attach_label_to_element(nil, nil) )
      CircleElementService.attach_label_to_element( element, dependency )
      element.text.should eql("junit:1.0.1")
    end

  end

end
