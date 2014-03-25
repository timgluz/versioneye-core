require 'spec_helper'

describe CircleElementService do

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
