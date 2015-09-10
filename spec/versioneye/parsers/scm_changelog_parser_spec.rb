require 'spec_helper'

test_case_url = "https://s3.amazonaws.com/veye_test_env/build.sbt"

describe ScmChangelogParser do

  describe "parse" do
    it "parse content from file" do
      gemfile = "spec/fixtures/files/changelog.xml"
      file = File.open(gemfile, "rb")
      content = file.read

      parser  = ScmChangelogParser.new
      entries = parser.parse( content )
      expect( entries ).to_not be_nil
      expect( entries.count ).to eq(4)
      expect( entries.first.author ).to eq('Robert Reiz <robert.reiz.81@gmail.com>')
    end
  end

end
