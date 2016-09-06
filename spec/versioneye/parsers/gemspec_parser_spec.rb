require 'spec_helper'

describe GemspecParser do
  let(:test_file_url){
    'https://s3.amazonaws.com/veye_test_env/veye.gemspec'
  }
  let(:test_file){ File.read 'spec/fixtures/files/rubygem/veye.gemspec'  }
  let(:parser){ GemspecParser.new }
  let(:product1){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'rake',
      name: 'rake',
      prod_type: Project::A_TYPE_RUBYGEMS,
      language: Product::A_LANGUAGE_RUBY,
      version: '1.10.1'
    ) 
  }
  let(:product2){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'gli',
      name: 'gli',
      prod_type: Project::A_TYPE_RUBYGEMS,
      language: Product::A_LANGUAGE_RUBY,
      version: '2.15'
    ) 
  }
  let(:product3){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'minitest',
      name: 'minitest',
      prod_type: Project::A_TYPE_RUBYGEMS,
      language: Product::A_LANGUAGE_RUBY,
      version: '6.2'
    ) 
  }
 

  context "parse_content" do
    before do
      product1.versions << FactoryGirl.build(:product_version, version: '0.8')
      product1.versions << FactoryGirl.build(:product_version, version: '0.9')
      product1.versions << FactoryGirl.build(:product_version, version: '1.10.1')
      product1.save

      product2.versions << FactoryGirl.build(:product_version, version: '2.0')
      product2.versions << FactoryGirl.build(:product_version, version: '2.15')
      product2.save

      product3.versions << FactoryGirl.build(:product_version, version: '5.9')
      product3.versions << FactoryGirl.build(:product_version, version: '6.2')
      product3.save
    end

    after do
      Product.delete_all
    end

    it "parses correctly a gemspec file" do
      proj = parser.parse_content(test_file, 'ftp://veye.gemspec')
      expect(proj).not_to be_nil

      expect(proj[:project_type]).to eq(Project::A_TYPE_RUBYGEMS)
      expect(proj[:language]).to eq(Product::A_LANGUAGE_RUBY)
      expect(proj.projectdependencies.size).to eq(4)
      expect(proj.unknown_number).to eq(1)
      expect(proj.out_number).to eq(1)

      dep1 = proj.projectdependencies[0]
      expect(dep1[:name]).to eq(product1[:name])
      expect(dep1[:version_requested]).to eq(product1[:version])
      expect(dep1[:version_current]).to eq(product1[:version])
      expect(dep1[:comperator]).to eq('>=')
      expect(dep1[:scope]).to eq(Dependency::A_SCOPE_RUNTIME)
      expect(dep1[:outdated]).to eq(false)

      dep2 = proj.projectdependencies[1]
      expect(dep2[:name]).to eq(product2[:name])
      expect(dep2[:version_requested]).to eq(product2[:version])
      expect(dep2[:version_current]).to eq(product2[:version])
      expect(dep2[:comperator]).to eq('~>')
      expect(dep2[:scope]).to eq(Dependency::A_SCOPE_RUNTIME)
      expect(dep2[:outdated]).to eq(false)

      dep3 = proj.projectdependencies[2]
      expect(dep3[:name]).to eq(product3[:name])
      expect(dep3[:version_requested]).to eq('5.9')
      expect(dep3[:version_current]).to eq(product3[:version])
      expect(dep3[:comperator]).to eq('~>')
      expect(dep3[:scope]).to eq(Dependency::A_SCOPE_DEVELOPMENT)
      expect(dep3[:outdated]).to eq(true)
    
      dep4 = proj.projectdependencies[3]
      expect(dep4[:name]).to eq('unknown')
      expect(dep4[:version_requested]).to eq('> 0')
      expect(dep4[:version_current]).to eq(nil)
      expect(dep4[:comperator]).to eq('=')
      expect(dep4[:scope]).to eq(Dependency::A_SCOPE_RUNTIME)
      expect(dep4[:outdated]).to be_falsey
    end

    it "parses correctly a gemspec fetched from the url" do
      proj = parser.parse(test_file_url)
      expect(proj).not_to be_nil

      expect(proj[:project_type]).to eq(Project::A_TYPE_RUBYGEMS)
      expect(proj[:language]).to eq(Product::A_LANGUAGE_RUBY)
      expect(proj.projectdependencies.size).to eq(3)
      expect(proj.unknown_number).to eq(0)
      expect(proj.out_number).to eq(1)

      dep1 = proj.projectdependencies[0]
      expect(dep1[:name]).to eq(product1[:name])
      expect(dep1[:version_requested]).to eq(product1[:version])
      expect(dep1[:version_current]).to eq(product1[:version])
      expect(dep1[:comperator]).to eq('>=')
      expect(dep1[:scope]).to eq(Dependency::A_SCOPE_RUNTIME)
      expect(dep1[:outdated]).to eq(false)

      dep2 = proj.projectdependencies[1]
      expect(dep2[:name]).to eq(product2[:name])
      expect(dep2[:version_requested]).to eq(product2[:version])
      expect(dep2[:version_current]).to eq(product2[:version])
      expect(dep2[:comperator]).to eq('~>')
      expect(dep2[:scope]).to eq(Dependency::A_SCOPE_RUNTIME)
      expect(dep2[:outdated]).to eq(false)

      dep3 = proj.projectdependencies[2]
      expect(dep3[:name]).to eq(product3[:name])
      expect(dep3[:version_requested]).to eq('5.9')
      expect(dep3[:version_current]).to eq(product3[:version])
      expect(dep3[:comperator]).to eq('~>')
      expect(dep3[:scope]).to eq(Dependency::A_SCOPE_DEVELOPMENT)
      expect(dep3[:outdated]).to eq(true)

    end
  end
end
