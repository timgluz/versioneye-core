require 'spec_helper'

describe Product do

  let(:product ) { Product.new(:language => Product::A_LANGUAGE_RUBY, :prod_key => "funny_bunny", :name => 'funny_bunny', :version => "1.0.0") }
  let(:version1) {FactoryGirl.build(:product_version, version: "0.0.1")}
  let(:version2) {FactoryGirl.build(:product_version, version: "0.0.2")}
  let(:version3) {FactoryGirl.build(:product_version, version: "0.1")}


  describe "save" do

    it "downcases the name" do
      product = described_class.new({:language => 'Java', :prod_type => 'Maven', :prod_key => 'junit', :name => 'JUnit'})
      expect( product.save ).to be_truthy
      expect( product.name_downcase ).to eq('junit')
    end
    it "downcases the name !" do
      product = described_class.new({:language => 'Java', :prod_type => 'Maven', :prod_key => 'junit', :name => 'JUnit'})

      expect( product.save! ).to be_truthy
      expect( product.name_downcase ).to eq('junit')
    end

  end


  describe "to_s" do
    it 'returns the correct to_s' do
      prod = Product.new({:language => 'Clojure', :prod_key => 'storm', :version => '1.0.0'})
      expect( prod.to_s ).to eq('<Product Clojure / storm (1.0.0) >')
    end
  end

  describe "name_and_version" do
    it 'returns the correct name and version' do
      prod = Product.new({:language => 'Clojure', :name => 'storm', :version => '1.0.0'})
      expect( prod.name_and_version ).to eq('storm : 1.0.0')
    end
  end


  describe "long_name" do
    it 'returns the long name' do
      prod = Product.new({:group_id => "org", :artifact_id => "apache"})
      expect( prod.long_name ).to eq("org:apache")
    end
    it 'returns the name' do
      prod = Product.new({:name => "org"})
      expect( prod.long_name ).to eq("org")
    end
  end


  describe "security_vulnerabilities" do
    it 'returns the sec. vuln.' do
      product = ProductFactory.create_for_maven 'junit', 'junit', '1.0.0'
      product.add_version('1.0.1')
      product.add_version('1.1.1')
      product.add_version('1.2.0')
      product.add_version('2.0.0')
      product.add_version('2.1.0')
      product.add_version('3.0.0')
      expect( product.save ).to be_truthy
      sv = SecurityVulnerability.new
      sv.language = product.language
      sv.prod_key = product.prod_key
      sv.save

      version_obj = product.version_by_number '2.1.0'
      version_obj.sv_ids = [sv.ids]
      version_obj.save

      version_obj = product.version_by_number '3.0.0'
      version_obj.sv_ids = [sv.ids]
      version_obj.save

      product.save
      product.reload

      product.version = '2.1.0'
      expect( product.security_vulnerabilities.first.ids ).to eql(sv.ids)

      product.version = '3.0.0'
      expect( product.security_vulnerabilities.first.ids ).to eql(sv.ids)

      product.version = '1.2.0'
      expect( product.security_vulnerabilities ).to be_nil
    end
  end


  describe "add_tag" do
    it 'adds the tag' do
      prod = Product.new({:group_id => "org", :artifact_id => "apache"})
      expect( prod.tags ).to be_nil
      prod.add_tag "xml"
      expect( prod.tags ).to_not be_nil
      expect( prod.tags.count ).to eq(1)
      expect( prod.tags.first ).to eq('xml')
      prod.add_tag "xml"
      expect( prod.tags.count ).to eq(1)
    end
  end


  describe "remove_tag" do
    it 'removes the tag' do
      prod = Product.new({:group_id => "org", :artifact_id => "apache"})
      expect( prod.tags ).to be_nil
      prod.add_tag "xml"
      expect( prod.tags ).to_not be_nil
      expect( prod.tags.count ).to eq(1)
      expect( prod.tags.first ).to eq('xml')
      prod.remove_tag "xml"
      expect( prod.tags.count ).to eq(0)
    end
  end


  describe "scm_changelogs" do
    it 'returns the scm_changelogs' do
      expect( ScmChangelogEntry.count ).to eq(0)
      product = ProductFactory.create_new
      scm_change = ScmChangelogEntry.new({:author => 'reiz',
        :file => 'pom.xml', :message => 'good change',
        :language => product.language, :prod_key => product.prod_key,
        :version => product.version})
      expect( scm_change.save ).to be_truthy
      logs = product.scm_changelogs
      expect( logs ).to_not be_nil
      expect( logs ).to_not be_empty
      expect( logs.count ).to eq(1)
      expect( ScmChangelogEntry.count ).to eq(1)
    end
    it 'returns an empty array' do
      expect( ScmChangelogEntry.count ).to eq(0)
      product = ProductFactory.create_new
      logs = product.scm_changelogs
      expect( logs ).to_not be_nil
      expect( logs ).to be_empty
      expect( logs.count ).to eq(0)
      expect( ScmChangelogEntry.count ).to eq(0)
    end
  end


  describe "find_by_id" do

    it "return nil. Because input is nil" do
      expect( described_class.find_by_id(nil) ).to be_nil
    end

    it "return nil. Because input is empty" do
      result = described_class.find_by_id("  ")
      expect( result ).to be_nil
    end

    it "return nil. Because there are no results." do
      result = described_class.find_by_id("gasflasjgfaskjgas848asjgfasgfasgf")
      expect( result ).to be_nil
    end

    it "returns the product for string id" do
      product = described_class.new({:language => 'Java', :prod_type => 'Maven', :prod_key => 'junit', :name => 'junit'})
      expect( product.save ).to be_truthy
      result = described_class.find_by_id( product.id.to_s )
      expect( result ).not_to be_nil
      expect( result.name ).to eq('junit')
    end

    it "returns the product for object id" do
      product = described_class.new({:language => 'Java', :prod_type => 'Maven', :prod_key => 'junit', :name => 'junit'})
      expect( product.save ).to be_truthy

      result = described_class.find_by_id( product.id )
      expect( result ).not_to be_nil
      expect( result.name ).to eq('junit')
    end

  end


  describe "fetch_product" do

    it "return nil. Because all inputs are nil" do
      expect( described_class.fetch_product(nil, nil) ).to be_nil
    end
    it "return nil. Because all inputs are empty" do
      expect( described_class.fetch_product('', '') ).to be_nil
    end
    it "return nil. Because prod_key is nil" do
      expect( described_class.fetch_product('ruby', nil) ).to be_nil
    end
    it "return nil. Because language is nil" do
      expect( described_class.fetch_product(nil, 'xiki') ).to be_nil
    end
    it "returns nil because the language is wrong" do
      product1 = ProductFactory.create_for_gemfile('bee', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save

      expect( described_class.fetch_product( Product::A_LANGUAGE_JAVA, "bee" ) ).to be_nil
    end
    it "returns nil because the prod_key is wrong" do
      product1 = ProductFactory.create_for_gemfile('bee', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save

      expect( described_class.fetch_product( Product::A_LANGUAGE_RUBY, "bee_bee" ) ).to be_nil
    end
    it "returns product for package language" do
      product1 = ProductFactory.create_for_gemfile('bee', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save
      result = described_class.fetch_product( 'package', "bee" )

      expect( result ).not_to be_nil
      expect( result.language ).to eq('Ruby')
      expect( result.prod_key ).to eq('bee')
    end
    it "returns the searched product" do
      product1 = ProductFactory.create_for_gemfile('bee', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save

      expect( described_class.fetch_product( Product::A_LANGUAGE_RUBY, 'Bee' ) ).not_to be_nil
      expect( described_class.fetch_product( Product::A_LANGUAGE_RUBY, 'bee' ) ).not_to be_nil

      result = described_class.fetch_product( Product::A_LANGUAGE_RUBY, 'bee' )

      expect( result ).not_to be_nil
      expect( result.prod_key ).to eql('bee')
    end

  end


  describe "fetch_bower" do
    it "return nil. Because input is nil" do
      result = described_class.fetch_bower(nil)
      expect( result ).to be_nil
    end
    it "return nil. Because input is empty" do
      result = described_class.fetch_bower("  ")
      expect( result ).to be_nil
    end
    it "return nil. Because there are no results." do
      result = described_class.fetch_bower("gasflasjgfaskjgas848asjgfasgfasgf")
      expect( result ).to be_nil
    end
    it "return searched product" do
      product = described_class.new({:language => 'JavaScript', :prod_type => 'Bower', :prod_key => 'moment/moment', :name => 'moment'})
      expect( product.save ).to be_truthy

      result = described_class.fetch_bower('moment')
      expect( result ).not_to be_nil
      expect( result.prod_key ).to eq('moment/moment')
      expect( result.name     ).to eq('moment')
    end
    it "return searched product, the first one" do
      product  = described_class.new({:language => 'JavaScript', :prod_type => 'Bower', :prod_key => 'moment/moment', :name => 'moment'})
      expect( product.save ).to be_truthy
      product2 = described_class.new({:language => 'JavaScript', :prod_type => 'Bower', :prod_key => 'moment/', :name => 'moment'})
      expect( product2.save ).to be_truthy
      result = described_class.fetch_bower('moment')
      expect( result ).not_to be_nil
      expect( result.prod_key ).to eq('moment/moment')
      expect( result.name ).to eq('moment')
    end
  end

  let(:cpan_prod1){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'DBD::SQLite',
      name: 'DBD-SQLite',
      name_downcase: 'dbd-sqlite',
      version: '1.54'
    )
  }

  let(:cpan_prod2){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'DBD',
      name: 'DBD',
      name_downcase: 'dbd',
      version: '0.2'
    )
  }

  let(:cpan_perl){
    Product.new(
      language: Product::A_LANGUAGE_PERL,
      prod_type: Project::A_TYPE_CPAN,
      prod_key: 'perl',
      name: 'perl',
      name_downcase: 'perl',
      version: '5.26',
      modules: ['File::Basename', 'Sys::Hostname']
    )
  }


  describe "fetch_cpan" do
    before do
      cpan_prod1.save
      cpan_prod2.save
      cpan_perl.save
    end

    it "finds match by parent module name" do
      prod = Product.fetch_cpan(cpan_prod1[:prod_key])

      expect(prod).not_to be_nil
      expect(prod[:language]).to eq(cpan_prod1[:language])
      expect(prod[:prod_type]).to eq(cpan_prod1[:prod_type])
      expect(prod[:prod_key]).to eq(cpan_prod1[:prod_key])
      expect(prod[:name]).to eq(cpan_prod1[:name])
    end

    it "finds match by submodule" do
      prod = Product.fetch_cpan('DBD::SQLite::VirtualTable::FileContent::Cursor')

      expect(prod).not_to be_nil
      expect(prod[:language]).to eq(cpan_prod1[:language])
      expect(prod[:prod_type]).to eq(cpan_prod1[:prod_type])
      expect(prod[:prod_key]).to eq(cpan_prod1[:prod_key])
      expect(prod[:name]).to eq(cpan_prod1[:name])
    end

    it "finds match by distribution id" do
      prod = Product.fetch_cpan('DBD-SQLite')

      expect(prod).not_to be_nil
      expect(prod[:language]).to eq(cpan_prod1[:language])
      expect(prod[:prod_type]).to eq(cpan_prod1[:prod_type])
      expect(prod[:prod_key]).to eq(cpan_prod1[:prod_key])
      expect(prod[:name]).to eq(cpan_prod1[:name])
    end

    it "finds match from perl submodule" do
      prod = Product.fetch_cpan('Sys::Hostname')

      expect(prod).not_to be_nil
      expect(prod[:language]).to eq(cpan_perl[:language])
      expect(prod[:prod_type]).to eq(cpan_perl[:prod_type])
      expect(prod[:prod_key]).to eq(cpan_perl[:prod_key])
      expect(prod[:name]).to eq(cpan_perl[:name])

    end
  end

  describe "find_by_key" do

    it "return nil. Because input is nil" do
      result = described_class.find_by_key(nil)
      expect( result ).to be_nil
    end
    it "return nil. Because input is empty" do
      result = described_class.find_by_key("  ")
      expect( result ).to be_nil
    end
    it "return nil. Because there are no results." do
      result = described_class.find_by_key("gasflasjgfaskjgas848asjgfasgfasgf")
      expect( result ).to be_nil
    end
    it "return searched product" do
      product = described_class.new({:language => 'Java', :prod_type => 'Maven', :prod_key => 'junit', :name => 'junit'})
      expect( product.save ).to be_truthy
      result = described_class.find_by_key('junit')

      expect( result ).not_to be_nil
      expect( result.prod_key ).to eq('junit')
      expect( result.name ).to eq('junit')
    end

  end


  describe "find_by_lang_key" do

    it "return nil. Because all inputs are nil" do
      expect( described_class.find_by_lang_key(nil, nil) ).to be_nil
    end
    it "return nil. Because all inputs are empty" do
      expect( described_class.find_by_lang_key('', '') ).to be_nil
    end
    it "return nil. Because prod_key is nil" do
      expect( described_class.find_by_lang_key('ruby', nil) ).to be_nil
    end
    it "return nil. Because language is nil" do
      expect( described_class.find_by_lang_key(nil, 'xiki') ).to be_nil
    end
    it "returns the searched product" do
      product1 = ProductFactory.create_for_gemfile('bee', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      product1.save

      expect( described_class.find_by_lang_key( Product::A_LANGUAGE_JAVA, "bee" ) ).to be_nil
      expect( described_class.find_by_lang_key( Product::A_LANGUAGE_RUBY, "Bee" ) ).to be_nil
      expect( described_class.find_by_lang_key( Product::A_LANGUAGE_RUBY.downcase, "bee") ).to be_nil

      result = described_class.find_by_lang_key( Product::A_LANGUAGE_RUBY, "bee" )
      expect( result ).not_to be_nil
      expect( result.prod_key ).to eql("bee")
    end

  end


  describe "find_by_group_and_artifact" do

    it "returns nil because of wrong parameters" do
      expect( described_class.find_by_group_and_artifact("bullshit", "bingo") ).to be_nil
    end
    it "returns nil because of wrong parameters" do
      expect( described_class.find_by_group_and_artifact('', '') ).to be_nil
    end
    it "returns nil because of wrong parameters" do
      expect( described_class.find_by_group_and_artifact(nil, nil) ).to be_nil
    end
    it "returns the correct product" do
      group = "junit56"
      artifact = "junit23"
      product.versions = Array.new
      product.name = artifact
      product.prod_key = "#{group}/#{artifact}"
      product.language = 'Java'
      product.prod_type = 'Maven'
      product.group_id = group
      product.artifact_id = artifact
      product.save

      prod = described_class.find_by_group_and_artifact(group, artifact)
      expect( prod ).not_to be_nil
      expect( prod.group_id ).to eql(group)
      expect( prod.artifact_id ).to eql(artifact)
    end
    it "returns the fallback product" do
      group = "junit56"
      artifact = "junit23"
      product.versions = Array.new
      product.name = artifact
      product.prod_key = "#{group}/#{artifact}"
      product.language = 'Java'
      product.prod_type = 'Maven'
      product.group_id = group
      product.artifact_id = artifact
      product.save

      prod = described_class.find_by_group_and_artifact(group, artifact, "Clojure")
      expect( prod ).not_to be_nil
      expect( prod.group_id     ).to eql(group)
      expect( prod.artifact_id  ).to eql(artifact)
      expect( prod.language     ).to eql('Java')
    end
    it "returns the clojure product" do
      group = "junit56"
      artifact = "junit23"
      product.versions = Array.new
      product.name = artifact
      product.prod_key = "#{group}/#{artifact}"
      product.language = 'Java'
      product.prod_type = 'Maven'
      product.group_id = group
      product.artifact_id = artifact
      product.save

      product_2 = Product.new
      product_2.versions = Array.new
      product_2.name = artifact
      product_2.prod_key = "#{group}/#{artifact}"
      product_2.language = 'Clojure'
      product_2.prod_type = 'Maven'
      product_2.group_id = group
      product_2.artifact_id = artifact
      expect( product_2.save ).to be_truthy

      prod = described_class.find_by_group_and_artifact(group, artifact, "Clojure")
      expect( prod ).not_to be_nil
      expect( prod.group_id ).to eql(group)
      expect( prod.artifact_id ).to eql(artifact)
      expect( prod.language   ).to eql('Clojure')
    end
  end


  describe "by_prod_keys" do

    it "returns nil because of wrong parameters" do
      expect( described_class.by_prod_keys(nil, nil) ).to be_empty
    end
    it "returns nil because of wrong parameters" do
      expect( described_class.by_prod_keys('', '') ).to be_empty
    end
    it "returns nil because of wrong parameters" do
      expect( described_class.by_prod_keys("bullshit", "bingo") ).to be_empty
    end
    it "returns the correct product" do
      product1 = ProductFactory.create_for_gemfile('xiki', '1.4.0')
      product1.versions.push( Version.new({version: '1.4.0'}) )
      expect( product1.save ).to be_truthy

      product2 = ProductFactory.create_for_gemfile('tire', '1.4.0')
      product2.versions.push( Version.new({version: '1.4.0'}) )
      expect( product2.save ).to be_truthy

      results = described_class.by_prod_keys(Product::A_LANGUAGE_RUBY, ['xiki', 'tire'])
      expect( results ).to_not be_nil
      expect( results.size ).to eq(2)
      expect( results.first.name ).to eq('xiki')
      expect( results.last.name ).to eq('tire')
    end

  end



  describe "version_by_number" do

    it "returns nil when number is nil" do
      expect( product.version_by_number(nil) ).to be_nil
    end

    it "returns nil when product has no versions" do
      expect( product.version_by_number("1.0.0") ).to be_nil
    end

    it "returns nil when prodoct has no matching versions" do
      product.versions << version1
      product.versions << version2
      product.save
      expect( product.version_by_number("1.0.0") ).to be_nil
    end

    it "returns correct version when there's matching version" do
      product.versions.delete_all
      product.versions << version1
      product.versions << version2
      product.save
      version = product.version_by_number("0.0.1")
      expect( version ).not_to be_nil
      expect( version.version ).to eq('0.0.1')
    end

    it "should find correct version when there's massive set of subdoc" do
      product.versions.delete_all
      40.times do |i|
        product.versions << FactoryGirl.build(:product_version, version: "0.#{i}.1")
      end
      product.save
      match = product.version_by_number("0.12.1")
      expect( match ).not_to be_nil
      expect( match[:version] ).to eql("0.12.1")
    end

    it "should find correct version even there may be versions with invalid or missing value" do
      product.versions.delete_all
      product.versions << version1
      product.versions << FactoryGirl.build(:product_version, version: nil)
      product.versions << FactoryGirl.build(:product_version, version: "")
      product.versions << FactoryGirl.build(:product_version, version: 1)
      product.versions << FactoryGirl.build(:product_version, version: 1.0)
      product.versions << FactoryGirl.build(:product_version, version: 1.minutes.ago)
      product.versions << version2
      product.save
      match = product.version_by_number(version2[:version])
      expect( match ).not_to be_nil
      expect( match[:version] ).to eql(version2[:version])
    end

  end


  describe 'versions_empty?' do

    it 'returns true if versions nil' do
      product = Product.new
      product.versions = nil
      expect( product.versions_empty?() ).to be_truthy
    end
    it 'returns true if versions empty' do
      product = Product.new
      product.versions = Array.new
      expect( product.versions_empty? ).to be_truthy
    end
    it 'returns false if versions not empty' do
      product = Product.new
      product.versions = Array.new
      product.versions.push(Version.new({:version => '1.0.0'}))
      expect( product.versions_empty? ).to be_falsey
    end

  end


  describe 'add_version' do

    it 'adds new version' do
      product = Product.new
      product.add_version('1.0.0')
      expect( product.versions.size ).to eq(1)
      expect( product.versions_empty? ).to be_falsey
      expect( product.version_by_number('1.0.0') ).not_to be_nil
    end

    it 'doesnt add new version because its existing already' do
      product = Product.new
      product.add_version('1.0.0')
      expect( product.versions.size ).to eq(1)
      product.add_version('1.0.0')

      expect( product.versions.size ).to eq(1)
      expect( product.versions_empty? ).to be_falsey
      expect( product.version_by_number('1.0.0') ).not_to be_nil
    end

  end


  describe 'add_repository' do

    it 'adds new repository' do
      product = Product.new
      product.add_repository "http://my_repo.org"
      expect(product.repositories.size).to eq(1)
      product.add_repository "http://my_repo.org"
      expect(product.repositories.size).to eq(1)
    end

    it 'doesnt add new version because its existing already' do
      product = Product.new
      product.add_repository "http://my_repo.org"
      expect(product.repositories.size).to eq(1)
      product.add_repository "http://my_repo.com"
      expect(product.repositories.size).to eq(2)
    end

  end


  describe 'remove_version' do

    it 'removes a version' do
      product = Product.new
      product.add_version('1.0.0')
      product.add_version('1.1.0')
      expect( product.versions.size ).to eq(2)
      expect( product.versions_empty? ).to be_falsey
      expect( product.remove_version('0.0.0') ).to be_falsey
      expect( product.remove_version('1.1.0') ).to be_truthy
      expect( product.version ).to eq('1.0.0')
    end

  end


  describe 'check_nil_version' do

    it 'returns nil' do
      product = Product.new
      product.check_nil_version
      expect( product.version ).to eq('0.0.0+NA')
    end
    it 'returns 1.0.0' do
      product = Product.new(:prod_type => 'Maven', :language => 'Java', :prod_key => 'junit', :name => 'name')
      product.versions.push(Version.new({:version => '1.0.0'}))
      product.check_nil_version
      expect( product.version ).to eq('1.0.0')
    end
    it 'returns 2.0.0' do
      product = Product.new({:version => '2.0.0'})
      product.check_nil_version
      expect( product.version ).to eq('2.0.0')
    end

  end


  describe 'add_svid' do

    it 'adds the sv id' do
      product = ProductFactory.create_for_maven 'junit', 'junit', '1.0.0'
      product.add_version('1.0.1')
      product.add_version('1.1.1')
      product.add_version('1.2.0')
      product.add_version('2.0.0')
      expect( product.save ).to be_truthy

      sv = SecurityVulnerability.new({:name_id => 'test', :language => product.language, :prod_key => product.prod_key})
      expect( sv.save ).to be_truthy

      expect( product.add_svid('1.0.1', sv) ).to be_truthy
      expect( product.add_svid('1.0.1', sv) ).to be_falsey

      product.reload
      version = product.version_by_number '1.0.1'
      expect( version.sv_ids.count ).to eql(1)
      expect( version.sv_ids.first ).to eql( sv.ids )
      version = product.version_by_number '1.0.0'
      expect( version.sv_ids ).to be_empty
    end

  end





  describe "encode_prod_key" do

    it "returns 0 for nil" do
      expect( described_class.encode_prod_key(nil) ).to eq("0")
    end
    it "returns 0 for empty string" do
      expect( described_class.encode_prod_key("") ).to eq("0")
    end
    it "returns 0 for empty string after strip" do
      expect( described_class.encode_prod_key("  ") ).to eq("0")
    end
    it "returns rails" do
      expect( described_class.encode_prod_key('rails') ).to eq('rails')
    end
    it "returns zend:zend" do
      expect( described_class.encode_prod_key('zend/zend') ).to eq('zend:zend')
    end

  end

  describe "decode_prod_key" do

    it "returns nil for nil" do
      expect( described_class.decode_prod_key(nil) ).to be_nil
    end
    it "returns nil for empty string" do
      expect( described_class.decode_prod_key("") ).to be_nil
    end
    it "returns nil for empty string after strip" do
      expect( described_class.decode_prod_key("  ") ).to be_nil
    end
    it "returns rails" do
      expect( described_class.decode_prod_key('rails') ).to eq('rails')
    end
    it "returns zend/zend" do
      expect( described_class.decode_prod_key('zend:zend') ).to eq('zend/zend')
    end

  end


  describe "encode_language" do

    it "returns nil for nil" do
      expect( described_class.encode_language(nil) ).to be_nil
    end
    it "returns nil for empty string" do
      expect( described_class.encode_language("") ).to be_nil
    end
    it "returns 0 for empty string after strip" do
      expect( described_class.encode_language("  ") ).to be_nil
    end
    it "returns php" do
      expect( described_class.encode_language('php') ).to eq('php')
    end
    it "returns php" do
      expect( described_class.encode_language('PHP') ).to eq('php')
    end
    it "returns nodejs" do
      expect( described_class.encode_language('Node.JS') ).to eq('nodejs')
    end
    it "returns objective-c" do
      expect( described_class.encode_language('Objective-C') ).to eq('objective-c')
    end

  end


  describe "decode_language" do

    it "returns nil for nil" do
      expect( described_class.decode_language(nil) ).to be_nil
    end
    it "returns nil for empty string" do
      expect( described_class.decode_language("") ).to be_nil
    end
    it "returns 0 for empty string after strip" do
      expect( described_class.decode_language("  ") ).to be_nil
    end
    it "returns PHP" do
      expect( described_class.decode_language('php') ).to eq(described_class::A_LANGUAGE_PHP)
    end
    it "returns Node.JS" do
      expect( described_class.decode_language('nodejs') ).to eq(described_class::A_LANGUAGE_NODEJS)
    end
    it "returns Objective-C" do
      expect( described_class.decode_language('objective-c') ).to eq(described_class::A_LANGUAGE_OBJECTIVEC)
    end
    it "returns JavaScript" do
      expect( described_class.decode_language('javascript') ).to eq(described_class::A_LANGUAGE_JAVASCRIPT)
    end
    it "returns Ruby" do
      expect( described_class.decode_language('ruby') ).to eq(described_class::A_LANGUAGE_RUBY)
    end
    it "returns Ruby" do
      expect( described_class.decode_language('rUBy') ).to eq(described_class::A_LANGUAGE_RUBY)
    end

  end


  describe 'language_esc' do

    it 'returns ruby' do
      product = described_class.new({:language => Product::A_LANGUAGE_RUBY})
      expect( product.language_esc ).to eq('ruby')
    end
    it 'returns nodejs' do
      product = described_class.new({:language => Product::A_LANGUAGE_NODEJS})
      expect( product.language_esc ).to eq('nodejs')
    end
    it 'returns objective-c' do
      product = described_class.new({:language => Product::A_LANGUAGE_OBJECTIVEC})
      expect( product.language_esc ).to eq('objective-c')
    end
    it 'returns titi' do
      product = described_class.new({:language => Product::A_LANGUAGE_OBJECTIVEC})
      expect( product.language_esc('TiTi') ).to eq('titi')
    end

  end


  describe "http_links" do

    it "returns an empty array" do
      expect( product.http_links.size ).to eq(0)
    end

    it "returns one link" do
      link = Versionlink.new({language: product.language, prod_key: product.prod_key})
      link.link = "http://link.de"
      link.name = "Name"
      expect( link.save ).to be_truthy
      db_link = Versionlink.find(link.id)
      expect( db_link ).not_to be_nil
      links = product.http_links
      expect( links.size ).to eq(1)
      link.remove
    end

    it "returns an empty array" do
      link = Versionlink.new
      link.language = product.language
      link.prod_key = product.prod_key
      link.link = "http://link.de"
      link.version_id = "nope"
      link.name = "Name"
      link.save
      expect( product.http_links.size ).to eq(0)
      link.remove
    end

    it "returns 1 link" do
      link = Versionlink.new({language: product.language, prod_key: product.prod_key})
      link.link = "http://link.de"
      link.version_id = "1.1"
      link.name = "Name"
      link.save
      product.version = "1.1"
      expect( product.http_version_links.size ).to eq(1)
      link.remove
    end

    it "returns 2 link2 for combined results" do
      link = Versionlink.new({language: product.language, prod_key: product.prod_key})
      link.link = "http://link1.de"
      link.name = "Name1"
      link.save

      link2 = Versionlink.new({language: product.language, prod_key: product.prod_key})
      link2.link = "http://link2.de"
      link2.version_id = "1.1"
      link2.name = "Name2"
      link2.save

      product.version = "1.1"
      expect( product.http_version_links_combined.size ).to eq(2)
      link.remove
      link2.remove
    end

  end


  describe 'http_version_links_combined' do
    it 'returns the right number of links' do
      link = Versionlink.new({language: product.language, prod_key: product.prod_key})
      link.link = "http://link1.de"
      link.name = "Docu"
      link.save

      sleep 1

      link2 = Versionlink.new({language: product.language, prod_key: product.prod_key})
      link2.link = "http://link2.de"
      link2.name = "Docu"
      link2.save
      link2.reload

      product.version = "1.1"
      expect( product.http_version_links_combined.size ).to eq(1)
      expect( product.http_version_links_combined.first.updated_at ).to_not eq(link.updated_at)
      expect( product.http_version_links_combined.first.updated_at ).to eq(link2.updated_at)

      link.remove
      link2.remove
    end
  end


  describe "handling product licenses" do
    it "returns licence of product, that is added by crawler" do
      product1 = ProductFactory.create_for_gemfile("bee", "1.4.0")
      product1.versions.push( Version.new({version: "1.4.0"}) )
      product1.save
      license = License.new({:language => product1.language, :prod_key => product1.prod_key,
        :version => product1.version, :name => "MIT"})
      license.save

      expect( product1.license_info ).to eql("MIT")
      license = License.new({:language => product1.language, :prod_key => product1.prod_key,
        :version => product1.version, :name => "GLP"})
      license.save

      expect( product1.licenses.count ).to eq(2)
      expect( product1.license_info ).to match("MIT")
      expect( product1.license_info ).to match("GLP")
    end

    it "returns unified licenses" do
      product1 = ProductFactory.create_for_gemfile("bee", "1.4.0")
      product1.versions.push( Version.new({version: "1.4.0"}) )
      product1.save
      license = License.new({:language => product1.language, :prod_key => product1.prod_key,
        :version => product1.version, :name => "MIT"})
      license.save

      expect( product1.license_info ).to eql("MIT")
      license = License.new({:language => product1.language, :prod_key => product1.prod_key,
        :version => product1.version, :name => "The MIT License"})
      license.save
      expect( product1.licenses.count ).to eq(1)
      expect( product1.licenses.first.name_substitute ).to eq("MIT")
    end
  end

  describe "unique_languages_for_product_ids" do

    it "returns unique languages for the product" do
      product_1 = ProductFactory.create_new 1
      product_2 = ProductFactory.create_new 2
      product_3 = ProductFactory.create_new 3, Project::A_TYPE_COMPOSER
      languages = described_class.unique_languages_for_product_ids( [product_1.id, product_2.id, product_3.id] )
      expect( languages.size ).to eq(2)
      expect( languages.include?("PHP")   ).to be_truthy
      expect( languages.include?("Java")  ).to be_truthy
    end

  end

end
