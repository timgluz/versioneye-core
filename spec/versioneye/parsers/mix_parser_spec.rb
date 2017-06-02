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

  context "extract_dep_items" do
    it "pull out all the dependency items from dependency block" do
      txt = '[ {:ex_spec, "~> 2.0.0"}, {:ex_doc, "~> 0.14"} ]'
      res = parser.extract_dep_items txt
      expect(res).not_to be_nil
      expect(res.is_a?(Array)).to be_truthy
      expect(res.size).to eq(2)
      expect(res[0]).to eq('{:ex_spec, "~> 2.0.0"}')
      expect(res[1]).to eq('{:ex_doc, "~> 0.14"}')
    end
  end

  context "parse_dep_item" do
    it "returns correct value for basic dep string" do
      dep_dt = parser.parse_dep_item('{:ex_spec, "~> 2.0.0"}')
      expect(dep_dt).not_to be_nil
      expect(dep_dt[:name]).to eq('ex_spec')
      expect(dep_dt[:version]).to eq('~> 2.0.0')
    end

    it "returns the correct value when user attached only 1 scope" do
      dep_dt = parser.parse_dep_item('{:ex_spec, only: :dev}')
      expect(dep_dt).not_to be_nil
      expect(dep_dt[:name]).to eq('ex_spec')
      expect(dep_dt[:version]).to be_nil
      expect(dep_dt[:scope]).to eq('dev')
    end

    it "returns the correct value when user attache list of scopes" do
      dep_dt = parser.parse_dep_item('{:ex_spec, only: [:test, :dev]}')
      expect(dep_dt).not_to be_nil
      expect(dep_dt[:name]).to eq('ex_spec')
      expect(dep_dt[:scope]).to eq('test') #NB! Projectdependencies support only 1scope
      expect(dep_dt[:version]).to be_nil
    end

    it "adds github dependency as version label and tag" do
      dep_dt = parser.parse_dep_item('{:ex_spec, git: "https://test.url", tag: "0.1.0"}')
      expect(dep_dt).not_to be_nil
      expect(dep_dt[:name]).to eq('ex_spec')
      expect(dep_dt[:version]).to eq('git:https://test.url')
      expect(dep_dt[:tag]).to eq('0.1.0')
    end
  end

  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_type: Project::A_TYPE_HEX,
      prod_key: "ex_spec",
      name: "ex_spec",
      version: '2.0.2'
    )
  }

  let(:prod2){
    Product.new(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_type: Project::A_TYPE_HEX,
      prod_key: "ex_doc",
      name: "ex_doc"
    )
  }

  let(:prod3){
    Product.new(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_type: Project::A_TYPE_HEX,
      prod_key: "benchfella",
      name: "benchfella"
    )
  }

  let(:prod4){
    Product.new(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_type: Project::A_TYPE_HEX,
      prod_key: "dialyze",
      name: "ex_spec"
    )
  }

  let(:prod5){
    Product.new(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_type: Project::A_TYPE_HEX,
      prod_key: "mix_test_watch",
      name: "mix_test_watch"
    )
  }

  let(:dep1){
    Projectdependency.new(
      language: Product::A_LANGUAGE_ELIXIR,
      name: 'ex_spec',
      version_label: "== 2.0.0",
      scope: "test"
    )
  }

  context "parse_requested_version" do
    before do
      prod1.versions << Version.new(version: '1.9.0')
      prod1.versions << Version.new(version: '2.0.2')
      prod1.versions << Version.new(version: '2.1.0')
    end

    it "returns current product version when version_label is null" do
      prod1.versions = []
      prod1.versions << Version.new(version: '2.0.2')
      prod1.save

      dep = parser.parse_requested_version(nil, dep1, prod1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq(prod1[:version])
      expect(dep[:version_label]).to be_nil
      expect(dep[:comperator]).to eq('=')
    end

    it "returns unmodified version label if no such product" do
      dep = parser.parse_requested_version("~> 1.0.0", dep1, nil)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('~> 1.0.0')
      expect(dep[:version_label]).to eq('~> 1.0.0')
      expect(dep[:comperator]).to eq('=')
    end

    it "returns correct fixed version" do
      prod1.save

      dep = parser.parse_requested_version('== 2.0.2', dep1, prod1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('2.0.2')
      expect(dep[:version_label]).to eq('== 2.0.2')
      expect(dep[:comperator]).to eq('=')
    end

    it "returns latest version for `>= 2.0.2`" do
      prod1.save

      dep = parser.parse_requested_version('>= 2.0.2', dep1, prod1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('2.1.0')
      expect(dep[:version_label]).to eq('>= 2.0.2')
      expect(dep[:comperator]).to eq('>=')
    end

    it "returns latest version for `> 2.0.2`" do
      prod1.save

      dep = parser.parse_requested_version('> 2.0.2', dep1, prod1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('2.1.0')
      expect(dep[:version_label]).to eq('> 2.0.2')
      expect(dep[:comperator]).to eq('>')
    end

    it "returns correct version for `<= 2.0.2`" do
      prod1.save

      dep = parser.parse_requested_version('<= 2.0.2', dep1, prod1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('2.0.2')
      expect(dep[:version_label]).to eq('<= 2.0.2')
      expect(dep[:comperator]).to eq('<=')
    end

    it "returns correct version for `< 2.0.2`" do
      prod1.save

      dep = parser.parse_requested_version('< 2.0.2', dep1, prod1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('1.9.0')
      expect(dep[:version_label]).to eq('< 2.0.2')
      expect(dep[:comperator]).to eq('<')
    end

    it "return biggest version in minor range" do
      prod1.versions = []
      prod1.versions << Version.new(version: '1.9.0')
      prod1.versions << Version.new(version: '2.0.0')
      prod1.versions << Version.new(version: '2.0.1')
      prod1.versions << Version.new(version: '2.0.2')
      prod1.versions << Version.new(version: '2.1.0')
      prod1.save

      dep = parser.parse_requested_version('~> 2.0.0', dep1, prod1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('2.0.2')
      expect(dep[:version_label]).to eq('~> 2.0.0')
      expect(dep[:comperator]).to eq('~>')
    end

    it "returns biggest version in major range" do
      prod1.versions = []
      prod1.versions << Version.new(version: '1.9.0')
      prod1.versions << Version.new(version: '2.0.0')
      prod1.versions << Version.new(version: '2.0.1')
      prod1.versions << Version.new(version: '2.0.2')
      prod1.versions << Version.new(version: '2.1.0')
      prod1.versions << Version.new(version: '3.0.0')
      prod1.save

      dep = parser.parse_requested_version('~> 2.0', dep1, prod1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('2.1.0')
      expect(dep[:version_label]).to eq('~> 2.0')
      expect(dep[:comperator]).to eq('~>')
    end

    it "can handle Git dependency" do
      dep = parser.parse_requested_version('git:https://test', dep1, prod1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('GIT')
      expect(dep[:version_label]).to eq('GIT')
      expect(dep[:comperator]).to eq('=')
    end

    it "handles Github dependency properly" do
      dep = parser.parse_requested_version('github:ninenines/cowboy', dep1, prod1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('GITHUB')
      expect(dep[:version_label]).to eq('GITHUB')
      expect(dep[:comperator]).to eq('=')
    end

    it "handles PATH dependency properly" do
      dep = parser.parse_requested_version('path:lib/ex.mix', dep1, prod1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('PATH')
      expect(dep[:version_label]).to eq('PATH')
      expect(dep[:comperator]).to eq('=')
    end
  end
end
