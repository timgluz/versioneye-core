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

    it "detects scoped requirement scope" do
      the_rule = parser.rules[:scoped_requires]

      expect(the_rule.match('test_requires "Test::More";')[:scope]).to eq('test')
      expect(the_rule.match('test_requires "Net::Ping", "2.41";')[:scope]).to eq('test')
      expect(the_rule.match('build_requires "Test::More";')[:scope]).to eq('build')
      expect(the_rule.match('configure_requires "Test::More";')[:scope]).to eq('configure')
      expect(the_rule.match('author_requires "Test::More";')[:scope]).to eq('author')
    end
  end

  let(:test_file){ File.read('spec/fixtures/files/cpan/cpanfile') }
  let(:test_file2){ File.read('spec/fixtures/files/cpan/cpanfile2') }

  let(:product1){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'Plack',
      name: 'Plack',
      name_downcase: 'plack',
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
      name_downcase: 'json',
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

  let(:depx){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_PERL,
      version_label: '',
      version_requested: '',
      comperator: '?'
    )
  }

  context "parse_requested_version" do
    before do
      product1.versions << FactoryGirl.build(:product_version, version: '0.8')
      product1.versions << FactoryGirl.build(:product_version, version: '0.9')
      product1.versions << FactoryGirl.build(:product_version, version: '1.0')
      product1.save
    end

    after do
      Product.delete_all
    end

    it "returns the product version if version_label is empty" do
      dep = parser.parse_requested_version('', depx, product1)
      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('1.0')
      expect(dep[:version_label]).to eq('>= 0')
      expect(dep[:comperator]).to eq('>=')
    end

    it "returns the product version if version_label == 0" do
      dep = parser.parse_requested_version('0', depx, product1)
      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('1.0')
      expect(dep[:version_label]).to eq('>= 0')
      expect(dep[:comperator]).to eq('>=')
    end

    it "returns greater version thats newer than 0.8" do
      depx[:version_label] = '0.8'
      dep = parser.parse_requested_version(depx[:version_label], depx, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('1.0')
      expect(dep[:version_label]).to eq(depx[:version_label])
      expect(dep[:comperator]).to eq('>=')
    end

    it "returns exact match" do
      depx[:version_label] = '== 0.9'
      dep = parser.parse_requested_version(depx[:version_label], depx, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.9')
      expect(dep[:version_label]).to eq(depx[:version_label])
      expect(dep[:comperator]).to eq('==')
    end

    it "returns correct less than version" do
      depx[:version_label] = '< 0.9'
      dep = parser.parse_requested_version(depx[:version_label], depx, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.8')
      expect(dep[:version_label]).to eq(depx[:version_label])
      expect(dep[:comperator]).to eq('<')
    end

    it "returns correct less or equal version" do
      depx[:version_label] = '<= 0.9'
      dep = parser.parse_requested_version(depx[:version_label], depx, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.9')
      expect(dep[:version_label]).to eq(depx[:version_label])
      expect(dep[:comperator]).to eq('<=')
    end

    it "returns correct greater than version " do
      depx[:version_label] = '> 0.9'
      dep = parser.parse_requested_version(depx[:version_label], depx, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('1.0')
      expect(dep[:version_label]).to eq(depx[:version_label])
      expect(dep[:comperator]).to eq('>')
    end

    it "returns correct greater or equal than version" do
      depx[:version_label] = '>= 0.9'
      dep = parser.parse_requested_version(depx[:version_label], depx, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('1.0')
      expect(dep[:version_label]).to eq(depx[:version_label])
      expect(dep[:comperator]).to eq('>=')
    end

    it "returns exludes correct version " do
      depx[:version_label] = '!= 1.0'
      dep = parser.parse_requested_version(depx[:version_label], depx, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.9')
      expect(dep[:version_label]).to eq(depx[:version_label])
      expect(dep[:comperator]).to eq('!=')
    end

    it "returns correct result for combined exluding ranges" do
      depx[:version_label] = '!= 0.8, != 1.0'
      dep = parser.parse_requested_version(depx[:version_label], depx, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.9')
      expect(dep[:version_label]).to eq(depx[:version_label])
      expect(dep[:comperator]).to eq('!=,!=')
    end

    it "returns correct result from combined range selectors" do
      depx[:version_label] = '> 0.8, < 1.0'
      dep = parser.parse_requested_version(depx[:version_label], depx, product1)

      expect(dep).not_to be_nil
      expect(dep[:version_requested]).to eq('0.9')
      expect(dep[:version_label]).to eq(depx[:version_label])
      expect(dep[:comperator]).to eq('>,<')
    end
  end

  context "parse_content" do
    before do
      product1[:version] = '1.0'
      product1.versions << FactoryGirl.build(:product_version, version: '0.9')
      product1.versions << FactoryGirl.build(:product_version, version: '1.0')
      product1.save

      product2[:version] = '3.0'
      product2.versions << FactoryGirl.build(:product_version, version: '2.0')
      product2.versions << FactoryGirl.build(:product_version, version: '2.50')
      product2.versions << FactoryGirl.build(:product_version, version: '2.80')
      product2.versions << FactoryGirl.build(:product_version, version: '3.0')
      product2.save

      product3[:version] = '2.5'
      product3.versions << FactoryGirl.build(:product_version, version: '1.9')
      product3.versions << FactoryGirl.build(:product_version, version: '2.0')
      product3.versions << FactoryGirl.build(:product_version, version: '2.5')

      product4[:version] = '2.0'
      product4.versions << FactoryGirl.build(:product_version, version: '0.9')
      product4.versions << FactoryGirl.build(:product_version, version: '1.5')
      product4.versions << FactoryGirl.build(:product_version, version: '1.8')
      product4.versions << FactoryGirl.build(:product_version, version: '2.0')

      product5[:version] = '1.30'
      product5.versions << FactoryGirl.build(:product_version, version: '1.10')
      product5.versions << FactoryGirl.build(:product_version, version: '1.20')
      product5.versions << FactoryGirl.build(:product_version, version: '1.30')

      product6[:version] = '0.5'
      product6.versions << FactoryGirl.build(:product_version, version: '0.5')
      product6.save

    end

    it "extracts correct products and version labels" do
      proj = parser.parse_content(test_file, "ftp://spec")
      expect( proj ).not_to be_nil

      expect( proj.out_number).to eq(2)
      expect( proj.unknown_number).to eq(1)
      expect( proj.dependencies.size ).to eq(7)

      deps = proj.dependencies
      expect(deps[0].prod_key).to eq(product1[:prod_key])
      expect(deps[0].version_requested).to eq('1.0')
      expect(deps[0].version_label).to eq('1.0')
      expect(deps[0].comperator).to eq('>=')
      expect(deps[0].outdated).to be_falsey
      expect(deps[0].scope).to eq(Dependency::A_SCOPE_RUNTIME)

      expect(deps[1].prod_key).to eq(product2[:prod_key])
      expect(deps[1].version_requested).to eq('2.50')
      expect(deps[1].version_label).to eq('>= 2.00, < 2.80')
      expect(deps[1].comperator).to eq('>=,<')
      expect(deps[1].outdated).to be_truthy
      expect(deps[1].scope).to eq(Dependency::A_SCOPE_RUNTIME)

      expect(deps[2].prod_key).to eq(product3[:prod_key])
      expect(deps[2].version_requested).to eq('2.5')
      expect(deps[2].version_label).to eq('2.0')
      expect(deps[2].comperator).to eq('>=')
      expect(deps[2].outdated).to be_falsey
      expect(deps[2].scope).to eq(Dependency::A_SCOPE_RUNTIME)

      expect(deps[3].prod_key).to eq(product4[:prod_key])
      expect(deps[3].version_requested).to eq('1.8')
      expect(deps[3].version_label).to eq('>= 0.96, < 2.0')
      expect(deps[3].comperator).to eq('>=,<')
      expect(deps[3].outdated).to be_truthy
      expect(deps[3].scope).to eq(Dependency::A_SCOPE_TEST)

      expect(deps[4].prod_key).to eq(product5[:prod_key])
      expect(deps[4].version_requested).to eq('1.30')
      expect(deps[4].version_label).to eq('1.12')
      expect(deps[4].comperator).to eq('>=')
      expect(deps[4].outdated).to be_falsey
      expect(deps[4].scope).to eq(Dependency::A_SCOPE_TEST)

      expect(deps[5].prod_key).to eq(product6[:prod_key])
      expect(deps[5].version_requested).to eq('0.5')
      expect(deps[5].version_label).to eq('>= 0')
      expect(deps[5].comperator).to eq('>=')
      expect(deps[5].outdated).to be_falsey
      expect(deps[5].scope).to eq(Dependency::A_SCOPE_DEVELOPMENT)

      expect(deps[6].prod_key).to eq('DBD::SQLite')
      expect(deps[6].version_requested).to eq('')
      expect(deps[6].version_label).to eq('')
      expect(deps[6].comperator).to eq('?')
      expect(deps[6].outdated).to be_falsey
      expect(deps[6].scope).to eq(Dependency::A_SCOPE_RUNTIME)
    end

    it "parses correctly test file with scoped requires" do
      proj = parser.parse_content(test_file2, "ftp://scoped-requires-spec")
      expect(proj).not_to be_nil
      expect( proj.out_number).to eq(2)
      expect( proj.unknown_number).to eq(1)
      expect( proj.dependencies.size ).to eq(7)

      deps = proj.dependencies
      expect(deps[0].prod_key).to eq(product1[:prod_key])
      expect(deps[0].version_requested).to eq('1.0')
      expect(deps[0].version_label).to eq('1.0')
      expect(deps[0].comperator).to eq('>=')
      expect(deps[0].outdated).to be_falsey
      expect(deps[0].scope).to eq(Dependency::A_SCOPE_RUNTIME)

      expect(deps[1].prod_key).to eq(product2[:prod_key])
      expect(deps[1].version_requested).to eq('2.50')
      expect(deps[1].version_label).to eq('>= 2.00, < 2.80')
      expect(deps[1].comperator).to eq('>=,<')
      expect(deps[1].outdated).to be_truthy
      expect(deps[1].scope).to eq(Dependency::A_SCOPE_RUNTIME)

      expect(deps[2].prod_key).to eq(product3[:prod_key])
      expect(deps[2].version_requested).to eq('2.5')
      expect(deps[2].version_label).to eq('2.0')
      expect(deps[2].comperator).to eq('>=')
      expect(deps[2].outdated).to be_falsey
      expect(deps[2].scope).to eq(Dependency::A_SCOPE_RUNTIME)

      expect(deps[3].prod_key).to eq(product4[:prod_key])
      expect(deps[3].version_requested).to eq('1.8')
      expect(deps[3].version_label).to eq('>= 0.96, < 2.0')
      expect(deps[3].comperator).to eq('>=,<')
      expect(deps[3].outdated).to be_truthy
      expect(deps[3].scope).to eq(Dependency::A_SCOPE_TEST)

      expect(deps[4].prod_key).to eq(product5[:prod_key])
      expect(deps[4].version_requested).to eq('1.30')
      expect(deps[4].version_label).to eq('1.12')
      expect(deps[4].comperator).to eq('>=')
      expect(deps[4].outdated).to be_falsey
      expect(deps[4].scope).to eq(Dependency::A_SCOPE_TEST)

      expect(deps[5].prod_key).to eq(product6[:prod_key])
      expect(deps[5].version_requested).to eq('0.5')
      expect(deps[5].version_label).to eq('>= 0')
      expect(deps[5].comperator).to eq('>=')
      expect(deps[5].outdated).to be_falsey
      expect(deps[5].scope).to eq(Dependency::A_SCOPE_DEVELOPMENT)

      expect(deps[6].prod_key).to eq('DBD::SQLite')
      expect(deps[6].version_requested).to eq('')
      expect(deps[6].version_label).to eq('')
      expect(deps[6].comperator).to eq('?')
      expect(deps[6].outdated).to be_falsey
      expect(deps[6].scope).to eq(Dependency::A_SCOPE_CONFIGURE)
    end
  end
end
