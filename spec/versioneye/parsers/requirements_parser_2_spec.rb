require 'spec_helper'

describe RequirementsParser do
  let(:parser){ RequirementsParser.new }
  let(:test_file_url){ "https://s3.amazonaws.com/veye_test_env/python_2/requirements.txt" }
  let(:product1){
    create_product('anyjson', 'anyjson'  , '1.0.0', ['0.3.3', '0.3.4', '1.0.0' ])
  }

  describe "parse" do
    before do
      product1.save
    end

    it "parse from https the file correctly" do
      project = parser.parse test_file_url
      expect( project ).not_to be_nil
    end

    it "parse from http the file correctly" do
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/python_2/requirements.txt")
      expect( project ).not_to be_nil
      expect( project.dependencies.size ).to eql(49)

      dep_01 = fetch_by_prod_key product1[:prod_key], project.dependencies

      expect( dep_01.name ).to eql(product1[:name])
      expect( dep_01.version_current    ).to eql(product1[:version])
      expect( dep_01.version_requested  ).to eql("0.3.3")
      expect( dep_01.comperator     ).to eql("==")
      expect( dep_01.version_label  ).to eql('==0.3.3')
      expect( dep_01.outdated       ).to be_truthy
    end

  end

  def create_product(name, prod_key, version, versions = nil )
    product = Product.new(
      language: Product::A_LANGUAGE_PYTHON,
      prod_type: Project::A_TYPE_PIP,
      name: name,
      prod_key: prod_key,
      version: version
    )

    product.versions << Version.new(version: version ) if version
    versions.to_a.each do |ver|
      product.versions << Version.new(version: ver )
    end

    product
  end

  def fetch_by_prod_key( name, dependencies )
    dependencies.each do |dep|
      return dep if dep.prod_key.eql?(name)
    end
    nil
  end
end
