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
    
    deps = parser.parse_doc(test_file)
    expect(deps.count).to eq(13)

    expect(deps[0][:group]).to eq('*')
    expect(deps[0][:source]).to eq('nuget')
    expect(deps[0][:prod_key]).to eq('NUnit')
    expect(deps[0][:comperator]).to eq('~>')
    expect(deps[0][:version]).to eq('2.6.3')

    expect(deps[1][:group]).to eq('*')
    expect(deps[1][:source]).to eq('nuget')
    expect(deps[1][:prod_key]).to eq('DotNetZip')
    expect(deps[1][:comperator]).to eq('>=')
    expect(deps[1][:version]).to eq('1.9')

    expect(deps[2][:group]).to eq('*')
    expect(deps[2][:source]).to eq('nuget')
    expect(deps[2][:prod_key]).to eq('SourceLink.Fake')
    expect(deps[2][:comperator]).to eq('*')
    expect(deps[2][:version]).to eq('')

    expect(deps[3][:group]).to eq('*')
    expect(deps[3][:source]).to eq('github')
    expect(deps[3][:prod_key]).to eq('forki/Fs')
    expect(deps[3][:comperator]).to eq('*')
    expect(deps[3][:version]).to eq('')

    expect(deps[4][:group]).to eq('*')
    expect(deps[4][:source]).to eq('github')
    expect(deps[4][:prod_key]).to eq('fsharp/fsfoundation')
    expect(deps[4][:comperator]).to eq('=')
    expect(deps[4][:version]).to eq('gh-pages')

    expect(deps[5][:group]).to eq('*')
    expect(deps[5][:source]).to eq('github')
    expect(deps[5][:prod_key]).to eq('forki/FsUnit')
    expect(deps[5][:comperator]).to eq('=')
    expect(deps[5][:version]).to eq('7623fc13439f0e60bd05c1ed3b5f6dcb937fe468')

    expect(deps[6][:group]).to eq('*')
    expect(deps[6][:source]).to eq('git')
    expect(deps[6][:prod_key]).to eq('https://github.com/fsprojects/Paket.git')
    expect(deps[6][:comperator]).to eq('*')
    expect(deps[6][:version]).to eq('')

    expect(deps[7][:group]).to eq('*')
    expect(deps[7][:source]).to eq('git')
    expect(deps[7][:prod_key]).to eq('http://github.com/forki/AskMe.git')
    expect(deps[7][:comperator]).to eq('=')
    expect(deps[7][:version]).to eq('97ee5ae7074bdb414a3e5dd7d2f2d752547d0542')

    expect(deps[8][:group]).to eq('*')
    expect(deps[8][:source]).to eq('git')
    expect(deps[8][:prod_key]).to eq('https://github.com/fsprojects/Paket2.git')
    expect(deps[8][:comperator]).to eq('>=')
    expect(deps[8][:version]).to eq('1.0')

    expect(deps[9][:group]).to eq('*')
    expect(deps[9][:source]).to eq('gist')
    expect(deps[9][:prod_key]).to eq('Thorium/1972349')
    expect(deps[9][:comperator]).to eq('*')
    expect(deps[9][:version]).to eq('')

    expect(deps[10][:group]).to eq('*')
    expect(deps[10][:source]).to eq('http')
    expect(deps[10][:prod_key]).to eq('http://www.fssnip.net/1n')
    expect(deps[10][:comperator]).to eq('*')
    expect(deps[10][:version]).to eq('')

    expect(deps[11][:group]).to eq('Test')
    expect(deps[11][:source]).to eq('nuget')
    expect(deps[11][:prod_key]).to eq('NUnit.Runners')
    expect(deps[11][:comperator]).to eq('*')
    expect(deps[11][:version]).to eq('')

    expect(deps[12][:group]).to eq('Test')
    expect(deps[12][:source]).to eq('nuget')
    expect(deps[12][:prod_key]).to eq('NUnit')
    expect(deps[12][:comperator]).to eq('*')
    expect(deps[12][:version]).to eq('')

    end
  end
end
