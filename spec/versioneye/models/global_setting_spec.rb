require 'spec_helper'

describe GlobalSetting do

  describe "default" do

    it "checks the default values" do
      described_class.count.should == 0

      # creates the first entry
      gs = described_class.default
      gs.should_not be_nil
      described_class.count.should == 1

      # Returns the existing entry
      gs = described_class.default
      described_class.count.should == 1

      gs.server_url.should_not be_nil
    end

  end

end
