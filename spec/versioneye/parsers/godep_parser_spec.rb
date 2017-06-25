require 'spec_helper'

describe GodepParser do
  let(:test_file_url){}
  let(:test_file){ File.read("spec/fixtures/files/golang/Godeps.json") }
  let(:parser){ GodepParser.new }

  let(:shax){ '0d7f52660096c5a22f2cb95c102e0693f773a593' }
  let(:product1_sha){ "0754dfcca172cfc4c07a61c123b23e5127d26760" }

  let(:product1){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "github.com/OpenBazaar/go-blockstackclient",
      name: "github.com/OpenBazaar/go-blockstackclient",
      prod_type: Project::A_TYPE_GODEP,
      language: Product::A_LANGUAGE_GO,
      version: '0.0.0+0754dfcca172cfc4c07a61c123b23e5127d26760'
    )
  }
  let(:product2){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "github.com/btcsuite/btcd/blockchain",
      name: "github.com/btcsuite/btcd/blockchain",
      prod_type: Project::A_TYPE_GODEP,
      language: Product::A_LANGUAGE_GO,
      version: "2.0"
    )
  }

  let(:product3){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "github.com/btcsuite/seelog",
      name: "github.com/btcsuite/seelog",
      prod_type: Project::A_TYPE_GODEP,
      language: Product::A_LANGUAGE_GO,
      version: "3.1.0"
    )
  }

  let(:product4){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: "github.com/fatih/color",
      name: "github.com/fatih/color",
      prod_type: Project::A_TYPE_GODEP,
      language: Product::A_LANGUAGE_GO,
      version: "0.2.0"
    )
  }

  context "extract_product_ids" do
    it "returns correct product ids for spec file" do
      res = parser.extract_product_ids test_file
      expect(res).not_to be nil
      expect(res.size).to eq(4)
      expect(res[0]).to eq('github.com/OpenBazaar/go-blockstackclient')
      expect(res[1]).to eq('github.com/btcsuite/btcd/blockchain')
      expect(res[2]).to eq('github.com/btcsuite/seelog')
      expect(res[3]).to eq('github.com/fatih/color')
    end
  end


  context "parse_requested_version" do
    let(:dep_empty){
      FactoryGirl.create(
        :projectdependency,
        language: Product::A_LANGUAGE_GO,
        version_requested: ''
      )
    }

    it "returns current product version if version_label is empty" do
      product1.versions << FactoryGirl.build(
        :product_version,
        version: "0.0.0+0754dfcca172cfc4c07a61c123b23e5127d26760",
        commit_sha: "0754dfcca172cfc4c07a61c123b23e5127d26760"
      )

      dep = parser.parse_requested_version(nil, dep_empty, product1)
      expect( dep ).not_to be_nil
      expect( dep[:version_label] ).to be_nil
      expect( dep[:version_requested] ).to eq( product1[:version] )
      expect( dep[:outdated] ).to be_falsey
    end

    it "returns requested raw label when product is nil" do
      dep = parser.parse_requested_version("3.1.4", dep_empty, nil)
      expect( dep ).not_to be_nil
      expect( dep[:version_label] ).to eq('3.1.4')
      expect( dep[:version_requested] ).to eq('3.1.4')
      expect( dep[:outdated] ).to be_falsey
    end

    it "returns unknown version when it doesnt find version by sha" do
      dep = parser.parse_requested_version(shax, dep_empty, product1)
      expect( dep ).not_to be_nil
      expect( dep[:version_label] ).to eq(shax)
      expect( dep[:version_requested] ).to eq('0.0.0+NA')
      expect( dep[:outdated] ).to be_falsey
    end

    it "returns dependency that uses semver matching with the corresponding sha" do
      product2.versions.delete_all
      product2.versions << FactoryGirl.build(:product_version, version: "1.6", commit_sha: shax)
      product2.versions << FactoryGirl.build(:product_version, version: '2.0', commit_sha: "222")

      prod2_dep = parser.init_dependency(product2, 'Godep2')
      dep = parser.parse_requested_version(shax, prod2_dep, product2)
      expect( dep ).not_to be_nil
      expect( dep[:version_label] ).to eq(shax)
      expect( dep[:version_requested] ).to eq('1.6')
      expect( dep[:version_current] ).to eq(product2[:version])
      expect( dep[:outdated] ).to be_nil
    end

    it "returns dependency that uses semver matching with Comment tag on the line" do
      tag = 'BTCD_0_12_0_BETA-88-g0d7f526'
      product3.versions.delete_all
      product3.versions << FactoryGirl.build(:product_version, version: '2.8.2', tag: tag)
      product3.versions << FactoryGirl.build(:product_version, version: '3.1.0', tag: 'v3.1.0')

      prod3_dep = parser.init_dependency(product3, 'Godep3')
      dep = parser.parse_requested_version(shax, prod3_dep, product3, tag)
      expect( dep ).not_to be_nil
      expect( dep[:version_label] ).to eq(tag)
      expect( dep[:version_requested] ).to eq('2.8.2')
      expect( dep[:version_current] ).to eq( product3[:version] )
    end
  end

  context "parse_content" do
    let(:product2_tag){ 'BTCD_0_12_0_BETA-88-g0d7f526' }

    before do
      product1.versions << FactoryGirl.build(
        :product_version,
        version: "0.0.0+0754dfcca172cfc4c07a61c123b23e5127d26760",
        commit_sha: product1_sha
      )
      product1.save

      product2.versions << FactoryGirl.build(:product_version, version: "1.6", tag: product2_tag)
      product2.versions << FactoryGirl.build(:product_version, version: '2.0', sha1: "222")
      product2.save

      product3.delete #product.3 is should be unknown

      product4.versions.delete_all
      product4.versions << FactoryGirl.build(
        :product_version,
        version: '0.2.0',
        tag: 'v0.2.0',
        commit_sha: "87d4004f2ab62d0d255e0a38f1680aa534549fe3"
      )
      product4.save
    end

    after do
      Product.delete_all
    end

    it "parses test file correctly" do
      the_project = parser.parse_content test_file

      expect( the_project ).not_to be_nil
      expect( the_project.dep_number ).to eq(4)
      expect( the_project.unknown_number ).to eq(1) #product3
      expect( the_project.out_number ).to eq(1) #only product2
      expect( the_project.dependencies.size ).to eq(4)

      deps = the_project.dependencies

      expect( deps[0].name ).to eq(product1[:name] )
      expect( deps[0].prod_key ).to eq(product1[:prod_key])
      expect( deps[0].version_label ).to eq( product1_sha )
      expect( deps[0].version_requested ).to eq( "0.0.0+0754dfcca172cfc4c07a61c123b23e5127d26760" )
      expect( deps[0].version_current ).to eq(product1[:version] )
      expect( deps[0].outdated ).to be_falsey

      expect( deps[1].name ).to eq(product2[:name] )
      expect( deps[1].prod_key ).to eq(product2[:prod_key])
      expect( deps[1].version_label ).to eq( product2_tag )
      expect( deps[1].version_requested ).to eq( '1.6' )
      expect( deps[1].version_current ).to eq(product2[:version] )
      expect( deps[1].outdated ).to be_truthy

      expect( deps[2].name ).to eq(product3[:name] )
      expect( deps[2].prod_key ).to eq(product3[:prod_key])
      expect( deps[2].version_label ).to eq( "v2.1-84-g313961b" )
      expect( deps[2].version_requested ).to eq( "313961b101eb55f65ae0f03ddd4e322731763b6c" )
      expect( deps[2].version_current ).to eq('0.0.0+NA')
      expect( deps[2].outdated ).to be_falsey

      expect( deps[3].name ).to eq(product4[:name] )
      expect( deps[3].prod_key ).to eq(product4[:prod_key])
      expect( deps[3].version_label ).to eq( "v0.2.0" )
      expect( deps[3].version_requested ).to eq( '0.2.0' )
      expect( deps[3].version_current ).to eq('0.2.0')
      expect( deps[3].outdated ).to be_falsey

    end
  end
end
