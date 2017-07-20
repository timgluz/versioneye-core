require 'spec_helper'

describe Rebar3Parser do
  let(:parser){ Rebar3Parser.new }
  let(:test_content){ File.read 'spec/fixtures/files/hex/rebar.config' }

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

  context "extract_scm_label" do
    it "returns just scm label when it is string" do
      scm_doc = 'https://othersite.com/erlang/rebar1'
      res = parser.extract_scm_label('hg', scm_doc)
      expect(res).to eq('hg+https://othersite.com/erlang/rebar1')
    end

    it "returns correct label when array includes revision details" do
      scm_doc = ["git://github.com/erlang/rebar2.git", {:ref=>"aef728"}]
      res = parser.extract_scm_label('git', scm_doc)
      expect(res).to eq('git+git://github.com/erlang/rebar2.git#aef728')
    end

    it "returns correct label when array of SCM has no revision details" do
      scm_doc = ["git://github.com/erlang/rebar2.git", {:raw => true}]
      res = parser.extract_scm_label('git', scm_doc)
      expect(res).to eq('git+git://github.com/erlang/rebar2.git')
    end
  end

  context "extract_version_label" do
    it "returns match_all selector for empty doc" do
      version_doc = nil
      res = parser.extract_version_label(version_doc)
      expect(res).to eq('*')
    end

    it "returns plain version string when it is just string" do
      version_doc = '1.2.3'
      res = parser.extract_version_label(version_doc)
      expect(res).to eq('1.2.3')
    end

    it "returns version label when scm and version labels are mixed" do
      version_doc = ["3.*", {:git=>"git://github.com/erlang/rebar5.git"}, [:raw]]
      res = parser.extract_version_label(version_doc)
      expect(res).to eq('3.*')
    end

    it "doesnt care about order of items in the array of version items" do
      version_doc = [{:git=>"git://github.com/erlang/rebar5.git"}, [:raw], "3.1"]
      res = parser.extract_version_label(version_doc)
      expect(res).to eq('3.1')
    end

    it "returns scm label when array has no version label" do
      version_doc = [{:git=>"git://github.com/erlang/rebar5.git"}, [:raw]]
      res = parser.extract_version_label(version_doc)
      expect(res).to eq('git+git://github.com/erlang/rebar5.git')
    end

    it "returns scm label when doc is hash map" do
      version_doc = {:git=>["git://github.com/erlang/rebar2.git",
                            {:ref=>"aef728"}]}
      res = parser.extract_version_label(version_doc)
      expect(res).to eq('git+git://github.com/erlang/rebar2.git#aef728')
    end
  end

  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_ERLANG,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'erlware_commons',
      name: 'erlware_commons',
      version: '1.0.1'
    )
  }

  let(:prod2){
    Product.new(
      language: Product::A_LANGUAGE_ERLANG,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'getopt',
      name: 'erlware_commons',
      version: '0.8.2'
    )
  }

  let(:prod3){
    Product.new(
      language: Product::A_LANGUAGE_ERLANG,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'rebar1',
      name: 'rebar1',
      version: '1.3.0'
    )
  }
  let(:prod4){
    Product.new(
      language: Product::A_LANGUAGE_ERLANG,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'rebar2',
      name: 'rebar2',
      version: '1.4.0'
    )
  }

  let(:prod5){
    Product.new(
      language: Product::A_LANGUAGE_ERLANG,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'rebar3',
      name: 'rebar3',
      version: '1.5.0'
    )
  }

  let(:prod6){
    Product.new(
      language: Product::A_LANGUAGE_ERLANG,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'rebar4',
      name: 'rebar4',
      version: '1.6.0'
    )
  }

  let(:prod7){
    Product.new(
      language: Product::A_LANGUAGE_ERLANG,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'rebar5',
      name: 'rebar5',
      version: '1.7.0'
    )
  }

  let(:prod8){
    Product.new(
      language: Product::A_LANGUAGE_ERLANG,
      prod_type: Project::A_TYPE_HEX,
      prod_key: 'meck',
      name: 'meck',
      version: '0.8.7'
    )
  }

  context "parse_requested_version" do
    #TODO: finish
  end

  context "parse_content" do
    before do
      prod1.save
      prod2.save
      prod3.save
      prod4.save
      prod5.save
      prod6.save
      prod7.save
      prod8.save
    end

    it "parse correctly the test file" do
      proj = parser.parse_content test_content
      expect(proj).not_to be_nil
      expect(proj.dependencies.size).to eq(8)

      dep1 = proj.dependencies[0]
      expect(dep1).not_to be_nil
      expect(dep1[:language]).to eq(prod1[:language])
      expect(dep1[:prod_key]).to eq(prod1[:prod_key])
      expect(dep1[:version_current]).to eq(prod1[:version])
      expect(dep1[:version_label]).to eq('1.0.0')
      expect(dep1[:version_requested]).to be_nil
      expect(dep1[:comperator]).to eq('=')
      expect(dep1[:outdated]).to be_falsey

      dep2 = proj.dependencies[1]
      expect(dep2).not_to be_nil
      expect(dep2[:language]).to eq(prod2[:language])
      expect(dep2[:prod_key]).to eq(prod2[:prod_key])
      expect(dep2[:version_current]).to eq(prod2[:version])
      expect(dep2[:version_label]).to eq('0.8.2')
      expect(dep2[:version_requested]).to be_nil
      expect(dep2[:comperator]).to eq('=')
      expect(dep2[:outdated]).to be_falsey

      dep3 = proj.dependencies[2]
      expect(dep3).not_to be_nil
      expect(dep3[:language]).to eq(prod3[:language])
      expect(dep3[:prod_key]).to eq(prod3[:prod_key])
      expect(dep3[:version_current]).to eq(prod3[:version])
      expect(dep3[:version_label]).to eq('hg+https://othersite.com/erlang/rebar1')
      expect(dep3[:version_requested]).to be_nil
      expect(dep3[:comperator]).to eq('=')
      expect(dep3[:outdated]).to be_falsey

      dep4 = proj.dependencies[3]
      expect(dep4).not_to be_nil
      expect(dep4[:language]).to eq(prod4[:language])
      expect(dep4[:prod_key]).to eq(prod4[:prod_key])
      expect(dep4[:version_current]).to eq(prod4[:version])
      expect(dep4[:version_label]).to eq('git+git://github.com/erlang/rebar2.git#aef728')
      expect(dep4[:version_requested]).to be_nil
      expect(dep4[:comperator]).to eq('=')
      expect(dep4[:outdated]).to be_falsey

      dep5 = proj.dependencies[4]
      expect(dep5).not_to be_nil
      expect(dep5[:language]).to eq(prod5[:language])
      expect(dep5[:prod_key]).to eq(prod5[:prod_key])
      expect(dep5[:version_current]).to eq(prod5[:version])
      expect(dep5[:version_label]).to eq('.*')
      expect(dep5[:version_requested]).to be_nil
      expect(dep5[:comperator]).to eq('=')
      expect(dep5[:outdated]).to be_falsey

      dep6 = proj.dependencies[5]
      expect(dep6).not_to be_nil
      expect(dep6[:language]).to eq(prod6[:language])
      expect(dep6[:prod_key]).to eq(prod6[:prod_key])
      expect(dep6[:version_current]).to eq(prod6[:version])
      expect(dep6[:version_label]).to eq('git+git://github.com/erlang/rebar5.git')
      expect(dep6[:version_requested]).to be_nil
      expect(dep6[:comperator]).to eq('=')
      expect(dep6[:outdated]).to be_falsey

      dep7 = proj.dependencies[6]
      expect(dep7).not_to be_nil
      expect(dep7[:language]).to eq(prod7[:language])
      expect(dep7[:prod_key]).to eq(prod7[:prod_key])
      expect(dep7[:version_current]).to eq(prod7[:version])
      expect(dep7[:version_label]).to eq('3.*')
      expect(dep7[:version_requested]).to be_nil
      expect(dep7[:comperator]).to eq('=')
      expect(dep7[:outdated]).to be_falsey

      dep8 = proj.dependencies[7]
      expect(dep8).not_to be_nil
      expect(dep8[:language]).to eq(prod8[:language])
      expect(dep8[:prod_key]).to eq(prod8[:prod_key])
      expect(dep8[:version_current]).to eq(prod8[:version])
      expect(dep8[:version_label]).to eq('0.8.7')
      expect(dep8[:version_requested]).to be_nil
      expect(dep8[:comperator]).to eq('=')
      expect(dep8[:outdated]).to be_falsey


    end
  end
end
