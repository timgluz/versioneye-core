require 'spec_helper'

describe GovendorParser do
  let(:parser){GovendorParser.new}
  let(:test_content){ File.read 'spec/fixtures/files/golang/vendor.json' }

  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/aws/aws-sdk-go/aws',
      name: 'github.com/aws/aws-sdk-go/aws',
      version: '2.0.0'
    )
  }

  let(:prod2){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/aws/aws-sdk-go/aws/awserr',
      name: 'github.com/aws/aws-sdk-go/aws/awserr',
      version: '2.2.0'
    )
  }

  let(:prod3){
    Product.new(
      language: Product::A_LANGUAGE_GO,
      prod_type: Project::A_TYPE_GODEP,
      prod_key:  'github.com/aws/aws-sdk-go/aws/awsutil',
      name: 'github.com/aws/aws-sdk-go/aws/awsutil',
      version: '2.3.0'
    )
  }

  context "parse_content" do
    before do
      prod1.save
      prod2.save
      prod3.save
    end

    it "parses correct dependencies from the file" do
      proj = parser.parse_content test_content
      expect(proj).not_to be_nil
      expect(proj.dependencies.size).to eq(3)

      dep1 = proj.dependencies[0]
      expect(dep1).not_to be_nil
      expect(dep1[:language]).to eq(prod1[:language])
      expect(dep1[:prod_key]).to eq(prod1[:prod_key])
      expect(dep1[:version_label]).to eq('d54f7c6d021d8fca3275e29d13255ededdc54839')
      expect(dep1[:version_requested]).to eq('0.0.0+NA')
      expect(dep1[:outdated]).to be_truthy

      dep2 = proj.dependencies[1]
      expect(dep2).not_to be_nil
      expect(dep2[:language]).to eq(prod2[:language])
      expect(dep2[:prod_key]).to eq(prod2[:prod_key])
      expect(dep2[:version_label]).to eq('d54f7c6d021d8fca3275e29d13255ededdc54839')
      expect(dep2[:version_requested]).to eq('0.0.0+NA')
      expect(dep2[:outdated]).to be_truthy

      dep3 = proj.dependencies[2]
      expect(dep3).not_to be_nil
      expect(dep3[:language]).to eq(prod3[:language])
      expect(dep3[:prod_key]).to eq(prod3[:prod_key])
      expect(dep3[:version_label]).to eq('d54f7c6d021d8fca3275e29d13255ededdc54839')
      expect(dep3[:version_requested]).to eq('0.0.0+NA')
      expect(dep3[:outdated]).to be_truthy

    end
  end
end
