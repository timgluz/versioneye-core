require 'spec_helper'

class TestC
  include Comperators::Github
end

describe TestC do
  let(:cmp){ TestC.new }

  context "commit_sha?" do
    it "returns true for a valid long SHA1 values" do
      expect(cmp.commit_sha?('37bca6cc589031e788583713c21955a334ca1774')).to be_truthy
      expect(cmp.commit_sha?('f73693a16cdf594532ee4c423a46d32ce3430c4e')).to be_truthy
      expect(cmp.commit_sha?('86c2509f4c12c5d3bf9a486925ed051666ee2d97')).to be_truthy
    end

    it "returns true for shorts shas" do
      expect(cmp.commit_sha?('37bca6c')).to be_truthy
      expect(cmp.commit_sha?('20170712')).to be_truthy
    end

    it "returns false for typical semver or tags" do
      expect(cmp.commit_sha?('1')).to be_falsey
      expect(cmp.commit_sha?('2.0')).to be_falsey
      expect(cmp.commit_sha?('3.0.0')).to be_falsey
      expect(cmp.commit_sha?('master')).to be_falsey
      expect(cmp.commit_sha?('1-abcdef01234')).to be_falsey
    end
  end
end
