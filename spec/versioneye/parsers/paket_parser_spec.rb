require 'spec_helper'

describe PaketParser do
  let(:test_file_url){
    "spec/fixtures/files/nuget/paket.dependencies"
  }
  let(:test_file){
    File.read("spec/fixtures/files/nuget/paket.dependencies")
  }

  let(:prod1){
    FactoryGirl.create(
      :product_with_versions,
      prod_key: 'NUnit',
      name: 'NUnit',
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: '2.7'
    )
  }

  let(:parser){ PaketParser.new }

  context "comperator?" do
    it "matches with all the supported comperators" do
      expect(parser.comperator?('~>')).to be_truthy
      expect(parser.comperator?('==')).to be_truthy
      expect(parser.comperator?('<=')).to be_truthy
      expect(parser.comperator?('>=')).to be_truthy
      expect(parser.comperator?('=')).to be_truthy
      expect(parser.comperator?('<')).to be_truthy
      expect(parser.comperator?('<')).to be_truthy 
    end
  end

  context "semver?" do
    it "returns true for all the proper semvers" do
      expect(parser.semver?('2.6.4')).to be_truthy
      expect(parser.semver?('1.0+build54')).to be_truthy
    end
  end

  context "parser_doc" do
    it "extracts correct dependencies from the file" do
    
    deps = parser.parse_content(test_file)
    expect(deps.count).to eq(12)

    expect(deps[0][:group]).to eq('*')
    expect(deps[0][:source]).to eq('nuget')
    expect(deps[0][:prod_key]).to eq('DotNetZip')
    expect(deps[0][:comperator]).to eq('>=')
    expect(deps[0][:version]).to eq('1.9')

    expect(deps[1][:group]).to eq('*')
    expect(deps[1][:source]).to eq('nuget')
    expect(deps[1][:prod_key]).to eq('SourceLink.Fake')
    expect(deps[1][:comperator]).to eq('*')
    expect(deps[1][:version]).to eq('')

    expect(deps[2][:group]).to eq('*')
    expect(deps[2][:source]).to eq('github')
    expect(deps[2][:prod_key]).to eq('forki/Fs')
    expect(deps[2][:comperator]).to eq('*')
    expect(deps[2][:version]).to eq('')

    expect(deps[3][:group]).to eq('*')
    expect(deps[3][:source]).to eq('github')
    expect(deps[3][:prod_key]).to eq('fsharp/fsfoundation')
    expect(deps[3][:comperator]).to eq('=')
    expect(deps[3][:version]).to eq('gh-pages')

    expect(deps[4][:group]).to eq('*')
    expect(deps[4][:source]).to eq('github')
    expect(deps[4][:prod_key]).to eq('forki/FsUnit')
    expect(deps[4][:comperator]).to eq('=')
    expect(deps[4][:version]).to eq('7623fc13439f0e60bd05c1ed3b5f6dcb937fe468')

    expect(deps[5][:group]).to eq('*')
    expect(deps[5][:source]).to eq('git')
    expect(deps[5][:prod_key]).to eq('https://github.com/fsprojects/Paket.git')
    expect(deps[5][:comperator]).to eq('*')
    expect(deps[5][:version]).to eq('')

    expect(deps[6][:group]).to eq('*')
    expect(deps[6][:source]).to eq('git')
    expect(deps[6][:prod_key]).to eq('http://github.com/forki/AskMe.git')
    expect(deps[6][:comperator]).to eq('=')
    expect(deps[6][:version]).to eq('97ee5ae7074bdb414a3e5dd7d2f2d752547d0542')

    expect(deps[7][:group]).to eq('*')
    expect(deps[7][:source]).to eq('git')
    expect(deps[7][:prod_key]).to eq('https://github.com/fsprojects/Paket2.git')
    expect(deps[7][:comperator]).to eq('>=')
    expect(deps[7][:version]).to eq('1.0')

    expect(deps[8][:group]).to eq('*')
    expect(deps[8][:source]).to eq('gist')
    expect(deps[8][:prod_key]).to eq('Thorium/1972349')
    expect(deps[8][:comperator]).to eq('*')
    expect(deps[8][:version]).to eq('')

    expect(deps[9][:group]).to eq('*')
    expect(deps[9][:source]).to eq('http')
    expect(deps[9][:prod_key]).to eq('http://www.fssnip.net/1n')
    expect(deps[9][:comperator]).to eq('*')
    expect(deps[9][:version]).to eq('')

    expect(deps[10][:group]).to eq('Test')
    expect(deps[10][:source]).to eq('nuget')
    expect(deps[10][:prod_key]).to eq('NUnit.Runners')
    expect(deps[10][:comperator]).to eq('*')
    expect(deps[10][:version]).to eq('')

    expect(deps[11][:group]).to eq('Test')
    expect(deps[11][:source]).to eq('nuget')
    expect(deps[11][:prod_key]).to eq('NUnit')
    expect(deps[11][:comperator]).to eq('~>')
    expect(deps[11][:version]).to eq('2.6.3')
    end
  end

  let(:dep1){
    FactoryGirl.create(
      :projectdependency,
      prod_key: "NugetProd1",
      language: Product::A_LANGUAGE_CSHARP,
      name: "NugetProd1",
      version_current: "",
      version_requested: "0.1",
      comperator: "=",
      outdated: false
    )
  }

  let(:dep_empty){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_CSHARP,
      version_current: "",
      version_requested: ""
    )
  }
  
  let(:dep_star){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_CSHARP,
      version_current: "",
      version_requested: "0",
      comperator: "*"
    )
  }

  let(:dep_equal){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_CSHARP,
      version_requested: "2.0",
      comperator: "="
    )
  }

  let(:dep_gt){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_CSHARP,
      version_requested: "2.0",
      comperator: ">"
    )
  }

  let(:dep_gte){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_CSHARP,
      version_requested: "2.1",
      comperator: ">="
    )
  }

  let(:dep_st){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_CSHARP,
      version_requested: '2.0',
      comperator: '<'
    )
  }

  let(:dep_ste){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_CSHARP,
      version_requested: '2.0',
      comperator: '<='
    )
  }

  let(:dep_tilde){
    FactoryGirl.create(
      :projectdependency,
      language: Product::A_LANGUAGE_CSHARP,
      version_requested: '2.0',
      comperator: '~>'
    )
  }

  let(:prod2){
    FactoryGirl.create(
      :product_with_versions,
      versions_count: 3,
      prod_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      version: "2.0",
    )
  }

  #TODO: finish, add specs for each comperator
  context "parse_requested_version" do
    it "returns dependency with unchanged versions" do
      res = parser.parse_requested_version(dep1[:version_requested], dep1, nil)
      expect(res[:version_requested]).to eq(dep1[:version_requested])
      expect(res[:version_current]).to eq(dep1[:version_current])
    end

    it "uses latest product version if version_label is empty string" do
      prod2.add_version prod2[:version]
      res = parser.parse_requested_version(nil, dep_empty, prod2)

      expect(res[:version_requested]).to eq(prod2[:version])
      expect(res[:version_current]).to eq('') #TODO: shouldnt it == prod2.version?
      expect(res[:comperator]).to eq('=')
    end

    it "uses latest product version if comperator is '*'" do
      prod2.add_version prod2[:version]
      res = parser.parse_requested_version(dep_star[:version_requested], dep_star, prod2)

      expect(res[:version_requested]).to eq(prod2[:version])
      expect(res[:version_current]).to eq('')
      expect(res[:comperator]).to eq(dep_star[:comperator])
    end

    it "returns unchanged dependency version if comperator is '='" do
      res = parser.parse_requested_version(dep_equal[:version_requested], dep_equal, prod2)

      expect(res[:version_requested]).to eq(dep_equal[:version_requested])
      expect(res[:version_current]).to eq('0.1') #default value from factory
      expect(res[:comperator]).to eq(dep_equal[:comperator])
    end

    it "returns greatest version that matches version range" do
      prod2.add_version "1.8"
      prod2.add_version "2.0"
      prod2.add_version "2.4"

      res = parser.parse_requested_version(dep_gt[:version_requested], dep_gt, prod2)
      expect(res[:version_requested]).to eq('2.4')
      expect(res[:comperator]).to eq(dep_gt[:comperator])
    end

    it "returns greatest or equal version that matches comperator" do
      prod2.add_version "1.8"
      prod2.add_version "2.0"
      prod2.add_version "2.4"

      res = parser.parse_requested_version(dep_gte[:version_requested], dep_gte, prod2)
      expect(res[:version_requested]).to eq('2.4')
      expect(res[:comperator]).to eq(dep_gte[:comperator])
    end

    it "returns smallest than requested version" do
      prod2.add_version "1.8"
      prod2.add_version "2.0"
      prod2.add_version "2.4"

      res = parser.parse_requested_version(dep_st[:version_requested], dep_st, prod2)
      expect(res[:version_requested]).to eq('1.8')
      expect(res[:comperator]).to eq(dep_st[:comperator])
    end

    it "returns smaller or equal than requested version" do
      prod2.add_version "1.8"
      prod2.add_version "2.0"
      prod2.add_version "2.4"

      res = parser.parse_requested_version(dep_ste[:version_requested], dep_ste, prod2)
      expect(res[:version_requested]).to eq('2.0')
      expect(res[:comperator]).to eq(dep_ste[:comperator])
    end

    it "returns bigger than current but not major release" do
      prod2.add_version "1.8"
      prod2.add_version "2.0"
      prod2.add_version "2.4"
      prod2.add_version "3.0"

      res = parser.parse_requested_version(dep_tilde[:version_requested], dep_tilde, prod2)
      expect(res[:version_requested]).to eq('2.4')
      expect(res[:comperator]).to eq(dep_tilde[:comperator])
    end
  end

  let(:test_file_url){
    'https://s3.amazonaws.com/veye_test_env/nuget/paket.dependencies'
  }

  let(:prod3){
    FactoryGirl.create(
      :product_with_versions,
      name: 'NUnit',
      prod_key: 'NUnit',
      language: Product::A_LANGUAGE_CSHARP,
      prod_type: Project::A_TYPE_NUGET,
      version: "2.6.5",
      versions: [
        Version.new(version: '2.6'),
        Version.new(version: '2.6.4'),
        Version.new(version: '2.6.5')
      ]
    )
  }
  
  let(:prod4){
    FactoryGirl.create(
      :product_with_versions,
      name: 'DotNetZip',
      prod_key: 'DotNetZip',
      language: Product::A_LANGUAGE_CSHARP,
      prod_type: Project::A_TYPE_NUGET,
      version: '2.0',
      versions: [
        Version.new(version: '1.8'),
        Version.new(version: '1.9'),
        Version.new(version: '2.0')
      ]
    )
  }

  let(:prod5){
    FactoryGirl.create(
      :product_with_versions,
      name: 'SourceLink.Fake',
      prod_key: 'SourceLink.Fake',
      language: Product::A_LANGUAGE_CSHARP,
      prod_type: Project::A_TYPE_NUGET,
      version: '2.0',
      versions: [
        Version.new(version: '1.9'),
        Version.new(version: '2.0')
      ]
    )
  }
  
  let(:prod6){
    FactoryGirl.create(
      :product_with_versions,
      name: 'forki/Fs',
      prod_key: 'forki/Fs',
      language: Product::A_LANGUAGE_CSHARP,
      prod_type: Project::A_TYPE_NUGET,
      version: 'master'
    )
  }
  
  let(:prod7){
    FactoryGirl.create(
      :product_with_versions,
      name: 'fsharp/fsfoundation',
      prod_key: 'fsharp/fsfoundation',
      language: Product::A_LANGUAGE_CSHARP,
      prod_type: Project::A_TYPE_NUGET,
      version: 'gh-pages'
    )
  }

  let(:prod8){
    FactoryGirl.create(
      :product_with_versions,
      name: 'NUnit.Runners',
      prod_key: 'NUnit.Runners',
      language: Product::A_LANGUAGE_CSHARP,
      prod_type: Project::A_TYPE_NUGET,
      version: '1.1',
      versions: [
        Version.new(version: '0.9'),
        Version.new(version: '1.1')
      ]
    )
  }

  context "parse" do
    it "parses correctly a file from url" do
      #TODO: somehow FactoryGirl doesnt save products
      [prod3, prod4, prod5, prod6, prod7, prod8].each {|prod| prod.save}
      the_project = parser.parse(test_file_url)

      expect(the_project[:name]).to eq('Paket Project')
      expect(the_project[:language]).to eq(Product::A_LANGUAGE_CSHARP)
      expect(the_project[:project_type]).to eq(Project::A_TYPE_NUGET)
      expect(the_project[:url]).to eq(test_file_url)
      expect(the_project[:unknown_number]).to eq(6)
      expect(the_project.projectdependencies.length).to eq(12)

      dep1 = the_project.projectdependencies[0]
      expect(dep1[:language]).to eq(prod4[:language])
      expect(dep1[:prod_key]).to eq(prod4[:prod_key])
      expect(dep1[:version_requested]).to eq('2.0')
      expect(dep1[:version_label]).to eq('1.9') #version number in the file
      expect(dep1[:comperator]).to eq('>=')
      expect(dep1[:scope]).to eq('compile')

      dep2 = the_project.projectdependencies[1]
      expect(dep2[:language]).to eq(prod5[:language])
      expect(dep2[:prod_key]).to eq(prod5[:prod_key])
      expect(dep2[:version_requested]).to eq('2.0')
      expect(dep2[:version_label]).to eq('2.0') #uses product version if file had no version
      expect(dep2[:comperator]).to eq('*')
      expect(dep2[:scope]).to eq('compile')

      dep3 = the_project.projectdependencies[2]
      expect(dep3[:language]).to eq(prod6[:language])
      expect(dep3[:prod_key]).to eq(prod6[:prod_key])
      expect(dep3[:version_requested]).to eq(nil) #TODO: should it be LATEST_COMMIT?
      expect(dep3[:version_label]).to eq('master') #if git-dep and version nil, then master
      expect(dep3[:comperator]).to eq('*')
      expect(dep3[:scope]).to eq('compile')

      dep4 = the_project.projectdependencies[3]
      expect(dep4[:language]).to eq(prod7[:language])
      expect(dep4[:prod_key]).to eq(prod7[:prod_key])
      expect(dep4[:version_requested]).to eq('gh-pages') #
      expect(dep4[:version_label]).to eq('gh-pages') #if git-dep and version has tag
      expect(dep4[:comperator]).to eq('=')
      expect(dep4[:scope]).to eq('compile')

      dep5 = the_project.projectdependencies[4]
      expect(dep5[:language]).to eq(Product::A_LANGUAGE_CSHARP)
      expect(dep5[:prod_key]).to eq('forki/FsUnit')
      expect(dep5[:version_requested]).to eq('7623fc13439f0e60bd05c1ed3b5f6dcb937fe468') #
      expect(dep5[:version_label]).to eq('7623fc13439f0e60bd05c1ed3b5f6dcb937fe468') 
      expect(dep5[:comperator]).to eq('=')
      expect(dep5[:scope]).to eq('compile')

      dep6  = the_project.projectdependencies[5]
      expect(dep6[:language]).to eq(Product::A_LANGUAGE_CSHARP)
      expect(dep6[:prod_key]).to eq('https://github.com/fsprojects/Paket.git')
      expect(dep6[:version_requested]).to eq('')
      expect(dep6[:version_label]).to eq('')
      expect(dep6[:comperator]).to eq('*')
      expect(dep6[:scope]).to eq('compile')

      dep7 = the_project.projectdependencies[6]
      expect(dep7[:language]).to eq(Product::A_LANGUAGE_CSHARP)
      expect(dep7[:prod_key]).to eq('http://github.com/forki/AskMe.git')
      expect(dep7[:version_requested]).to eq('97ee5ae7074bdb414a3e5dd7d2f2d752547d0542')
      expect(dep7[:version_label]).to eq('97ee5ae7074bdb414a3e5dd7d2f2d752547d0542')
      expect(dep7[:comperator]).to eq('=')
      expect(dep7[:scope]).to eq('compile')

      dep8 =  the_project.projectdependencies[7]
      expect(dep8[:language]).to eq(Product::A_LANGUAGE_CSHARP)
      expect(dep8[:prod_key]).to eq('https://github.com/fsprojects/Paket2.git')
      expect(dep8[:version_requested]).to eq('1.0')
      expect(dep8[:version_label]).to eq('1.0')
      expect(dep8[:comperator]).to eq('>=')
      expect(dep8[:scope]).to eq('compile')

      dep9 = the_project.projectdependencies[8]
      expect(dep9[:language]).to eq(Product::A_LANGUAGE_CSHARP)
      expect(dep9[:prod_key]).to eq('Thorium/1972349')
      expect(dep9[:version_requested]).to eq('')
      expect(dep9[:version_label]).to eq('')
      expect(dep9[:comperator]).to eq('*')
      expect(dep9[:scope]).to eq('compile')

      dep10 = the_project.projectdependencies[9]
      expect(dep10[:language]).to eq(Product::A_LANGUAGE_CSHARP)
      expect(dep10[:prod_key]).to eq('http://www.fssnip.net/1n')
      expect(dep10[:version_requested]).to eq('')
      expect(dep10[:version_label]).to eq('')
      expect(dep10[:comperator]).to eq('*')
      expect(dep10[:scope]).to eq('compile')

      dep11 = the_project.projectdependencies[10]
      expect(dep11[:language]).to eq(prod8[:language])
      expect(dep11[:prod_key]).to eq(prod8[:prod_key])
      expect(dep11[:version_requested]).to eq('1.1')
      expect(dep11[:version_label]).to eq('1.1')
      expect(dep11[:comperator]).to eq('*')
      expect(dep11[:scope]).to eq('test')

      dep12 = the_project.projectdependencies[11]
      expect(dep12[:language]).to eq(prod3[:language])
      expect(dep12[:prod_key]).to eq(prod3[:prod_key])
      expect(dep12[:version_requested]).to eq('2.6.5')
      expect(dep12[:version_label]).to eq('2.6.3')
      expect(dep12[:comperator]).to eq('~>')
      expect(dep12[:scope]).to eq('test')
    end
  end
end
