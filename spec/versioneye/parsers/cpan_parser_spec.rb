require 'spec_helper'

describe CpanParser do
  let(:parser){ CpanParser.new  }

  context "parser rules" do
    it "matches with various versions" do
      the_rule = parser.rules[:version]

      expect(the_rule.match("1")[:version]).to eq('1')
      expect(the_rule.match("1.0")[:version]).to eq('1.0')
      expect(the_rule.match("1.0.1")[:version]).to eq('1.0.1')
      expect(the_rule.match('v1.0.1')[:version]).to eq('v1.0.1')
      expect(the_rule.match('1.0.1-pre')[:version]).to eq('1.0.1-pre')
      expect(the_rule.match('1.2.2-alpha.1')[:version]).to eq('1.2.2-alpha.1')
      expect(the_rule.match('1.2-alpha.1+build123')[:version]).to eq('1.2-alpha.1+build123')
    end

    it "matches compertors" do
      the_rule = parser.rules[:comperator]

      expect( the_rule.match('<')[:comperator] ).to eq('<')
      expect( the_rule.match('<=')[:comperator]).to eq('<=')
      expect( the_rule.match('>')[:comperator]).to eq('>')
      expect( the_rule.match('>=')[:comperator]).to eq('>=')
      expect( the_rule.match('==')[:comperator]).to eq('==')
      expect( the_rule.match('!=')[:comperator]).to eq('!=')
    end

    it "matches version range and comperators" do
      the_rule = parser.rules[:range]
      
      m = the_rule.match('== 0.14')
      expect( m ).not_to be_nil
      expect( m[:range] ).to eq('== 0.14')
      expect( m[:comperator]).to eq('==')
      expect( m[:version]).to eq('0.14')

      m = the_rule.match('>0.1.2')
      expect( m ).not_to be_nil
      expect( m[:range] ).to eq('>0.1.2')
      expect( m[:comperator] ).to eq('>')
      expect( m[:version] ).to eq('0.1.2')


      m = the_rule.match('1.3')
      expect( m ).not_to be_nil
      expect( m[:range] ).to eq('1.3')
      expect( m[:comperator] ).to be_nil
      expect( m[:version] ).to eq('1.3')
    end

    it "matches dependency name and version range" do
      the_rule = parser.rules[:dependency]

      m = the_rule.match('Plack, 1.0;')

      expect( m ).not_to be_nil
      expect( m[:package] ).to eq('Plack')
      expect( m[:range].to_s.strip ).to eq('1.0')
      expect( m[:comperator] ).to eq(nil)
      expect( m[:version].to_s.strip ).to eq('1.0')

      m = the_rule.match('JSON, >= 2.00, < 2.80;')
      expect( m ).not_to be_nil
      expect( m[:package] ).to eq('JSON')
      expect( m[:ranges] ).to eq('>= 2.00, < 2.80')
      expect( m[:range] ).to eq('< 2.80')
      expect( m[:comperator] ).to eq('<')
      expect( m[:version] ).to eq('2.80')
    end

    it "detects requirment line" do
      the_rule = parser.rules[:requires]
      expect(the_rule.match('requires "JSON", "3.0";')[1] ).to eq('requires')
      expect(the_rule.match('recommends "JSON", "3.0";')[1]).to eq('recommends')
      expect(the_rule.match('suggests "YAML", ">= 2.3";')[1]).to eq('suggests')
    end

    it "detects beginning of requirement block" do
      the_rule = parser.rules[:block_start]
      
      expect(the_rule.match('on develop => sub {')[1]).to eq('develop')
      expect(the_rule.match('on configure=>sub { ')[1]).to eq('configure')
      expect(the_rule.match('on test =>    sub {')[1]).to eq('test')
    end
  end

  context "parse_content" do
    let(:test_file){ File.read('spec/fixtures/files/cpan/cpanfile') }
    let(:product1){
      FactoryGirl.create(
        :product_with_versions,
        prod_key: 'Plack',
        name: 'Plack',
        prod_type: Project::A_TYPE_CPAN,
        language: Product::A_LANGUAGE_PERL,
        version: '1.0'
      )
    }

    let(:product2){
      FactoryGirl.create(
        :product_with_versions,
        prod_key: 'JSON',
        name: 'JSON',
        prod_type: Project::A_TYPE_CPAN,
        language: Product::A_LANGUAGE_PERL,
        version: '2.5'
      )
    }

    let(:product3){
      FactoryGirl.create(
        :product_with_versions,
        prod_key: 'JSON::XS',
        name: 'JSON::XS',
        prod_type: Project::A_TYPE_CPAN,
        language: Product::A_LANGUAGE_PERL,
        version: '2.0'
      )
    }
    let(:product4){
      FactoryGirl.create(
        :product_with_versions,
        prod_key: 'Test::More',
        name: 'Test::More',
        prod_type: Project::A_TYPE_CPAN,
        language: Product::A_LANGUAGE_PERL,
        version: '1.12'
      )
    }
    let(:product5){
      FactoryGirl.create(
        :product_with_versions,
        prod_key: 'Test::TCP',
        name: 'Test::TCP',
        prod_type: Project::A_TYPE_CPAN,
        language: Product::A_LANGUAGE_PERL,
        version: '1.12'
      )
    }
    let(:product6){
      FactoryGirl.create(
        :product_with_versions,
        prod_key: 'Devel::NYTProf',
        name: 'Devel::NYTProf',
        prod_type: Project::A_TYPE_CPAN,
        language: Product::A_LANGUAGE_PERL,
        version: '1.0'
      )
    }

    it "extracts correct products and version labels" do

    end
  end
end
