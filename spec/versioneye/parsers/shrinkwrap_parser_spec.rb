require 'spec_helper'

describe ShrinkwrapParser do
  let(:parser){ ShrinkwrapParser.new }
  let(:test_file){ File.read 'spec/fixtures/files/npm-shrinkwrap.json' }

  let(:product1){
    FactoryGirl.create(
      :product_with_versions,
      name: 'bower',
      prod_key: 'bower',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '1.4.1'
    )
  }

  let(:product2){
    FactoryGirl.create(
      :product_with_versions,
      name: 'archy',
      prod_key: 'archy',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '1.0.0'
    )
  }

  let(:product3){
    FactoryGirl.create(
      :product_with_versions,
      name: 'bower-config',
      prod_key: 'bower-config',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '0.6.1'
    )
  }

  let(:product4){
    FactoryGirl.create(
      :product_with_versions,
      name: 'graceful-fs',
      prod_key: 'graceful-fs',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '2.0.3'
    )
  }

  let(:product5){
    FactoryGirl.create(
      :product_with_versions,
      name: 'mout',
      prod_key: 'mout',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '0.9.1'
    )
  }

  let(:product6){
    FactoryGirl.create(
      :product_with_versions,
      name: 'optimist',
      prod_key: 'optimist',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '0.6.1'
    )
  }

  let(:product7){
    FactoryGirl.create(
      :product_with_versions,
      name: 'wordwrap',
      prod_key: 'wordwrap',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '0.0.3'
    )
  }

  let(:product8){
    FactoryGirl.create(
      :product_with_versions,
      name: 'minimist',
      prod_key: 'minimist',
      prod_type: Project::A_TYPE_NPM,
      language: Product::A_LANGUAGE_NODEJS,
      version: '0.1.0'
    )
  }

  context "parse_content" do
    before do
      product1.save
      product2.save
      product3.save
      product4.save
      product5.save
      product6.save
      product7.save
      product8.save
      product8.versions << FactoryGirl.build(:product_version, version: '0.0.10')
      product8.versions << FactoryGirl.build(:product_version, version: '0.1.0')
    end

    it "parses project file correctly" do
      proj = parser.parse_content test_file
      expect(proj).not_to be_nil
      expect(proj[:name]).to eq('baconsnake')
      expect(proj[:version]).to eq('0.1.0')
      expect(proj.dep_number).to eq(8)

      dep = proj.dependencies[0]
      expect(dep[:name]).to eq(product1[:name])
      expect(dep[:version_requested]).to eq(product1[:version])
      expect(dep[:version_current]).to eq(product1[:version])
      expect(dep[:outdated]).to be_falsey
      expect(dep[:transitive]).to be_falsey
      expect(dep[:deepness]).to eq(0)

      dep = proj.dependencies[1]
      expect(dep[:name]).to eq(product2[:name])
      expect(dep[:version_requested]).to eq(product2[:version])
      expect(dep[:version_current]).to eq(product2[:version])
      expect(dep[:outdated]).to be_falsey
      expect(dep[:transitive]).to be_truthy
      expect(dep[:deepness]).to eq(1)

      dep = proj.dependencies[2]
      expect(dep[:name]).to eq(product3[:name])
      expect(dep[:version_requested]).to eq(product3[:version])
      expect(dep[:version_current]).to eq(product3[:version])
      expect(dep[:outdated]).to be_falsey
      expect(dep[:transitive]).to be_truthy
      expect(dep[:deepness]).to eq(1)

      dep = proj.dependencies[3]
      expect(dep[:name]).to eq(product4[:name])
      expect(dep[:version_requested]).to eq(product4[:version])
      expect(dep[:version_current]).to eq(product4[:version])
      expect(dep[:outdated]).to be_falsey
      expect(dep[:transitive]).to be_truthy
      expect(dep[:deepness]).to eq(2)

      dep = proj.dependencies[4]
      expect(dep[:name]).to eq(product5[:name])
      expect(dep[:version_requested]).to eq(product5[:version])
      expect(dep[:version_current]).to eq(product5[:version])
      expect(dep[:outdated]).to be_falsey
      expect(dep[:transitive]).to be_truthy
      expect(dep[:deepness]).to eq(2)

      dep = proj.dependencies[5]
      expect(dep[:name]).to eq(product6[:name])
      expect(dep[:version_requested]).to eq(product6[:version])
      expect(dep[:version_current]).to eq(product6[:version])
      expect(dep[:outdated]).to be_falsey
      expect(dep[:transitive]).to be_truthy
      expect(dep[:deepness]).to eq(2)

      dep = proj.dependencies[6]
      expect(dep[:name]).to eq(product7[:name])
      expect(dep[:version_requested]).to eq(product7[:version])
      expect(dep[:version_current]).to eq(product7[:version])
      expect(dep[:outdated]).to be_falsey
      expect(dep[:transitive]).to be_truthy
      expect(dep[:deepness]).to eq(3)

      dep = proj.dependencies[7]
      expect(dep[:name]).to eq(product8[:name])
      expect(dep[:version_requested]).to eq('0.0.10')
      expect(dep[:version_current]).to eq(product8[:version])
      expect(dep[:outdated]).to be_truthy
      expect(dep[:transitive]).to be_truthy
      expect(dep[:deepness]).to eq(3)

    end
  end
end
