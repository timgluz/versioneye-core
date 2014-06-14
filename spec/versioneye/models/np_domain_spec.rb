require 'spec_helper'

describe NpDomain do

  describe "save" do

    it "saves" do
      described_class.new({:domain => "@haha.de", :free_projects => 1}).save.should be_true
    end
    it "saves" do
      described_class.new().save.should be_true
    end
    it "does not save because domain is nil" do
      npd = described_class.new()
      npd.domain = nil
      npd.save.should be_false
    end
    it "does not save because free projects is nil" do
      npd = described_class.new()
      npd.free_projects = nil
      npd.save.should be_false
    end
    it "does not save because domain exist already" do
      npd = described_class.new()
      npd.save.should be_true

      npd_2 = described_class.new()
      npd_2.save.should be_false
    end

  end

end
