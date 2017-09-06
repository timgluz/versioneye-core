require 'spec_helper'

describe RequirementsParser do
  let(:parser){ RequirementsParser.new }
  let(:test_content){ File.read 'spec/fixtures/files/pip/requirements.txt' }

  let(:product1){
    create_product('South'  , 'south'  , '1.0.0', ['0.7.3', '0.7.2', '1.0.0' ])
  }
  let(:product2){
    create_product('amqplib', 'amqplib', '2.0.0', ['1.0.2', '1.0.0', '2.0.0' ])
  }
  let(:product3){
    create_product('Django' , 'django' , '1.4.0', ['1.3.1', '1.3.5', '1.4.0' ])
  }
  let(:product4){ create_product('PIL'    , 'pil'    , '1.1.7' ) }
  let(:product5){ create_product('jsmin'  , 'jsmin'  , '1.1.7' ) }


  describe "parse" do
    before do
      product1.save
      product2.save
      product3.save
      product4.save
      product5.save
    end

    it "parse from http the file correctly" do
      project = parser.parse_content test_content
      expect( project ).not_to be_nil
      expect( project.dependencies.size ).to eql(22)

      dep_01 = project.dependencies[0]
      expect( dep_01.name ).to eql(product3[:name])
      expect( dep_01.version_requested ).to eql("1.3.1")
      expect( dep_01.version_current ).to eql(product3[:version])
      expect( dep_01.comperator ).to eql("==")

      dep_02 = project.dependencies[1]
      expect( dep_02.name ).to eql(product4[:name])
      expect( dep_02.version_requested  ).to eql(product4[:version])
      expect( dep_02.version_current    ).to eql(product4[:version])
      expect( dep_02.comperator         ).to eql("==")

      dep_03 = project.dependencies[2]
      expect( dep_03.name ).to eql(product1[:name])
      expect( dep_03.version_requested  ).to eql("0.7.3")
      expect( dep_03.version_current    ).to eql(product1[:version])
      expect( dep_03.comperator         ).to eql("<=")

      dep_04 = project.dependencies[3]
      expect( dep_04.name ).to eql(product2[:name])
      expect( dep_04.version_requested  ).to eql(product2[:version])
      expect( dep_04.version_current    ).to eql(product2[:version])
      expect( dep_04.comperator         ).to eql(">=")

      dep_05 = project.dependencies[20]
      expect( dep_05.name ).to eql(product5[:name])
      expect( dep_05.version_requested  ).to eql(product5[:version])
      expect( dep_05.version_current    ).to eql(product5[:version])
      expect( dep_05.comperator         ).to eql('>=')

      expect( project.dependencies.last.name ).to eql("emencia.django.newsletter")
    end

  end

  describe "extract_comparator" do

    it "returns the right split ==" do
      expect( parser.extract_comparator("django==1.0") ).to eql("==")
    end

    it "returns the right split <" do
      expect( parser.extract_comparator("django<1.0") ).to eql("<")
    end

    it "returns the right splitt <=" do
      expect( parser.extract_comparator("django<=1.0") ).to eql("<=")
    end

    it "returns the right splitt >" do
      expect( parser.extract_comparator("django>1.0") ).to eql(">")
    end

    it "returns the right splitt >=" do
      expect( parser.extract_comparator("django>=1.0") ).to eql(">=")
    end

    it "returns the right splitt !=" do
      expect( parser.extract_comparator("django!=1.0") ).to eql("!=")
    end

    it "returns nil" do
      expect( parser.extract_comparator("django") ).to be_nil
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

end
