require 'spec_helper'

describe PackageLockParser do
  let(:parser){ PackageLockParser.new }
  let(:test_content){ File.read 'spec/fixtures/files/npm/package-lock.json' }

  let(:product1){
    Product.new(
      language: Product::A_LANGUAGE_NODEJS,
      prod_type: Project::A_TYPE_NPM,
      prod_key: 'cacache',
      name: 'cacache',
      version: '9.2.6'
    )
  }

  let(:product2){
    Product.new(
      language: Product::A_LANGUAGE_NODEJS,
      prod_type: Project::A_TYPE_NPM,
      prod_key: 'duplexify',
      name: 'duplexify',
      version: '3.5.0'
    )
  }

  let(:product3){
    Product.new(
      language: Product::A_LANGUAGE_NODEJS,
      prod_type: Project::A_TYPE_NPM,
      prod_key: 'end-of-stream',
      name: 'end-of-stream',
      version: '1.0.0'
    )
  }

  let(:product4){
    Product.new(
      language: Product::A_LANGUAGE_NODEJS,
      prod_type: Project::A_TYPE_NPM,
      prod_key: 'tarball-http',
      name: 'tarball-http',
      version: '1.3.0'
    )
  }

  let(:product5){
    Product.new(
      language: Product::A_LANGUAGE_NODEJS,
      prod_type: Project::A_TYPE_NPM,
      prod_key: 'tarball-file',
      name: 'tarball-file',
      version: '1.3.1'
    )
  }


  context "parse_content" do
    before do
      product1.save
      product2.save

      product3.versions << Version.new(version: '1.1.0')
      product3.save
      product4.save
      product5.save
    end

    it "parses correctly project file" do
      proj = parser.parse_content test_content
      expect(proj).not_to be_nil
      expect(proj[:name]).to eq('pkg-lock-test')
      expect(proj[:version]).to eq('1.0.0')
      expect(proj.dep_number).to eq(5)

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
      expect(dep[:transitive]).to be_falsey
      expect(dep[:deepness]).to eq(0)

      dep = proj.dependencies[2]
      expect(dep[:name]).to eq(product3[:name])
      expect(dep[:version_requested]).to eq(product3[:version])
      expect(dep[:version_current]).to eq('1.1.0')
      expect(dep[:outdated]).to be_truthy
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


    end
  end
end
