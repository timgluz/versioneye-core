require 'spec_helper'

describe Rebar3Parser do
  let(:parser){ Rebar3Parser.new }

  context "preprocess_text" do
    it "removes line comments" do
      txt = <<-TXT
        %% remove me
        line1 %and me
        line2 % and from here
      TXT

      expect(parser.preprocess_text(txt)).to eq('line1 line2')
    end

    it "keeps string interpoletion" do
      txt = <<-TXT
        %% -*- mode: erlang
        "robocopy \"%REBAR_BUILD_DIR\%"" % string interpolation
        % should be gone
      TXT

      expect(parser.preprocess_text(txt)).to eq('"robocopy "%REBAR_BUILD_DIR%""')
    end
  end

  context "split_into_blocks" do
    it "returns correct 1 block from empty block" do
      txt = '{}'
      expect(parser.split_into_blocks(txt)).to eq(['{}'])
    end

    it "returns correct 1 block from preprocessed text" do
      txt = "{:deps [{:a,1}]}."
      res = parser.split_into_blocks(txt)

      expect(res.size).to eq(1)
      expect(res[0]).to eq('{:deps [{:a,1}]}')
    end

    it "returns 2 separate blocks" do
      txt = '{:deps ""} {:meta ""}'
      res = parser.split_into_blocks(txt)

      expect(res.size).to eq(2)
      expect(res[0]).to eq('{:deps ""}')
      expect(res[1]).to eq('{:meta ""}')
    end

    it "ignores comments when splitting" do
      txt = '%-- comment {:deps []} %mmooo '
      res = parser.split_into_blocks(txt)

      expect(res.size).to eq(1)
      expect(res[0]).to eq('{:deps []}')
    end
  end
end
