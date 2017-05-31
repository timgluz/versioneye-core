require 'spec_helper'

describe MixParser do
  let(:parser){ MixParser.new }
  let(:test_content){ File.read('spec/fixtures/files/hex/mix.exs') }

  context "preprocess text" do
    it "removes all oneline comments" do
      txt = %q[
        # comment 1
        defp  deps do # comment 2
          #### trollolo
          []
        end
      ]

      res = parser.preprocess txt
      expect(res.empty?).to be_falsey
      expect(res).to eq('defp deps do [] end')
    end

    it "removes new lines" do
      txt = %q[

        abc

      ]

      res = parser.preprocess txt
      expect(res).to eq('abc')
    end

    it "removes duplicate spaces" do
      txt = %q[
        abc       def
      ]

      res = parser.preprocess txt
      expect(res).to eq('abc def')
    end
  end

  context "extract_deps_block" do
    it "returns raw string between deps block" do
      txt = %q[
        defmodule Absinth.Mixfile do
          @version "1.3.1"

          defp project do
            [app: :absinthe]
          end

          defp deps do
            [
              {:ex_spec, "~> 2.0.0"},
              {:ex_doc, "~> 0.14"}
            ]
          end
        end
      ]

      clean_txt = parser.preprocess txt
      res = parser.extract_deps_block clean_txt
      expect(clean_txt.empty?).to be_falsey
      expect(res).to eq('[ {:ex_spec, "~> 2.0.0"}, {:ex_doc, "~> 0.14"} ]')
    end
  end
end
