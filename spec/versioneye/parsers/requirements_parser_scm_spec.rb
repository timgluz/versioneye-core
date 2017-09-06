require 'uri'

require 'spec_helper'

describe RequirementsParser do
  let(:parser){ RequirementsParser.new }

  describe "extract_egg_name" do
    it "returns correct name for git urls" do
      u = URI.parse( 'git://git.myproject.org/MyProject.git#egg=MyProject' )
      expect(parser.extract_egg_name(u)).to eq('MyProject')
    end

    it "returns correct name for git urls with revision details" do
      u = URI.parse 'git://git.myproject.org/MyProject.git@da39a3ee5e6b4b0d3255bfef95601890afd80709#egg=MyProject'
      expect(parser.extract_egg_name(u)).to eq('MyProject')
    end
  end

  describe "extract_scm_path" do
    it "returns path and no rev details" do
      u = URI.parse( 'git://git.myproject.org/MyProject.git#egg=MyProject' )
      path, rev = parser.extract_scm_details(u)

      expect(path).to eq('/MyProject.git')
      expect(rev).to be_nil
    end

    it "returns correct path and rev details" do
      u = URI.parse( 'git://git.myproject.org/MyProject.git@2.1.0-alpha#egg=MyProject' )
      path, rev = parser.extract_scm_details(u)

      expect(path).to eq('/MyProject.git')
      expect(rev).to eq('2.1.0-alpha')
    end
  end

  describe "scm_line?" do
    it "returns false for empty string" do
      expect(parser.scm_line?('')).to be_falsey
    end

    it "returns true for git line" do
      t = 'git+https://github.com/datagovuk/ckanext-harvest.git@2.0#egg=ckanext-harvest'
      expect(parser.scm_line?(t)).to be_truthy
    end

    it "returns true for hg line" do
      t = 'hg+https://hg.myproject.org/MyProject/#egg=MyProject'
      expect(parser.scm_line?(t)).to be_truthy
    end

    it "returns true for bzr line" do
      t = 'bzr+ftp://user@myproject.org/MyProject/trunk/#egg=MyProject'
      expect(parser.scm_line?(t)).to be_truthy
    end

    it "returns true svn line" do
      t = 'svn+svn://svn.myproject.org/svn/MyProject#egg=MyProject'
      expect(parser.scm_line?(t)).to be_truthy
    end

    it "ignores `-e` flag in the prefix" do
      t = '-e git://git.myproject.org/MyProject.git#egg=MyProject'
      expect(parser.scm_line?(t)).to be_truthy
    end
  end

  describe "extract_git_fullname" do
    it "returns correct repo fullname for basic url" do
      t = 'git+https://github.com/ckan/ckanext-qa'
      expect(parser.extract_git_fullname(t)).to eql('ckan/ckanext-qa')
    end

    it "returns repo fullname for github repo and ignore revision details" do
      t = 'git+https://github.com/datagovuk/ckanext-harvest.git@2.0#egg=ckanext-harvest'
      expect(parser.extract_git_fullname(t)).to eq('datagovuk/ckanext-harvest')
    end
  end

  describe "process_scm_line" do

    it "returns correct PIP line for git" do
      t = 'git+https://gitnob.com/datagovuk/ckanext-harvest.git@2.0#egg=ckanext-harvest'
      expected = 'ckanext-harvest==git+https://gitnob.com/datagovuk/ckanext-harvest.git#2.0'

      egg_line = parser.process_scm_line(t)
      expect(egg_line).to eq(expected)
    end

    it "returns correct PIP line for HG" do
      t = 'hg+ssh://hg@myproject.org/MyProject/#egg=MyProject'
      expected = 'MyProject==hg+ssh://myproject.org/MyProject'

      expect(parser.process_scm_line(t)).to eq(expected)
    end

    it "returns Github repo and rev for Github urls" do
      t = '-e git+https://github.com/datagovuk/ckanext-harvest.git@2.0#egg=ckanext-harvest'
      expected = 'ckanext-harvest==datagovuk/ckanext-harvest#2.0'

      expect(parser.process_scm_line(t)).to eq(expected)
    end
  end


  # tests for parsing the test file content
  let(:test_content){ File.read 'spec/fixtures/files/pip/requirements_scm.txt' }
  let(:prod1){
    Product.new(
      language: Product::A_LANGUAGE_PYTHON,
      prod_type: Project::A_TYPE_PIP,
      prod_key: 'ckanext-harvest',
      name: 'ckanext-harvest',
      version: '2.0'
    )
  }

  let(:prod2){
    Product.new(
      language: Product::A_LANGUAGE_PYTHON,
      prod_type: Project::A_TYPE_PIP,
      prod_key: 'ckanext-spatial',
      name: 'ckanext-spatial',
      version: '1.0.0'
    )
  }

  let(:prod3){
    Product.new(
      language: Product::A_LANGUAGE_PYTHON,
      prod_type: Project::A_TYPE_PIP,
      prod_key: 'ckanext-qa',
      name: 'ckanext-qa',
      version: '1.3.0'
    )
  }

  let(:prod4){
    Product.new(
      language: Product::A_LANGUAGE_PYTHON,
      prod_type: Project::A_TYPE_PIP,
      prod_key: 'Shapely',
      name: 'Shapely',
      version: '1.2.13'
    )
  }

  let(:prod5){
    Product.new(
      language: Product::A_LANGUAGE_PYTHON,
      prod_type: Project::A_TYPE_PIP,
      prod_key: 'owslib',
      name: 'owslib',
      version: '1.4.1'
    )
  }

  let(:prod6){
    Product.new(
      language: Product::A_LANGUAGE_PYTHON,
      prod_type: Project::A_TYPE_PIP,
      prod_key: 'lxml',
      name: 'lxml',
      version: '3.4.4'
    )
  }


  describe 'parse_content' do
    before do
      prod1.versions << Version.new(version: '2.0')
      prod1.save

      prod2.versions << Version.new(version: '1.0.0')
      prod2.save

      prod3.save

      prod4.versions << Version.new(version: '1.2.13')
      prod4.save

      prod5.versions << Version.new(version: '1.4.1')
      prod5.save

      prod6.save
    end

    it 'parses correctly the test file with SCM deps' do
      proj = parser.parse_content(test_content)
      expect(proj).not_to be_nil
      expect(proj.projectdependencies.size).to eq(6)

      dep1 = proj.projectdependencies[0]
      expect(dep1[:prod_key]).to eq(prod1[:prod_key])
      expect(dep1[:language]).to eq(prod1[:language])
      expect(dep1[:version_current]).to eq(prod1[:version])
      expect(dep1[:version_requested]).to eq('GITHUB')
      expect(dep1[:version_label]).to eq('==datagovuk/ckanext-harvest#2.0')
      expect(dep1[:comperator]).to eq('==')
      expect(dep1[:outdated]).to be_falsey

      dep2 = proj.projectdependencies[1]
      expect(dep2[:prod_key]).to eq(prod2[:prod_key])
      expect(dep2[:language]).to eq(prod2[:language])
      expect(dep2[:version_current]).to eq(prod2[:version])
      expect(dep2[:version_requested]).to eq('GITHUB')
      expect(dep2[:version_label]).to eq('==datagovuk/ckanext-spatial#dgu')
      expect(dep2[:comperator]).to eq('==')
      expect(dep2[:outdated]).to be_falsey

      dep3 = proj.projectdependencies[2]
      expect(dep3[:prod_key]).to eq(prod3[:prod_key])
      expect(dep3[:language]).to eq(prod3[:language])
      expect(dep3[:version_current]).to eq(prod3[:version])
      expect(dep3[:version_requested]).to eq('GITHUB')
      expect(dep3[:version_label]).to eq('==ckan/ckanext-qa')
      expect(dep3[:comperator]).to eq('==')
      expect(dep3[:outdated]).to be_falsey

      dep4 = proj.projectdependencies[3]
      expect(dep4[:prod_key]).to eq(prod4[:prod_key])
      expect(dep4[:language]).to eq(prod4[:language])
      expect(dep4[:version_current]).to eq(prod4[:version])
      expect(dep4[:version_requested]).to eq('1.2.13')
      expect(dep4[:version_label]).to eq('>=1.2.13')
      expect(dep4[:comperator]).to eq('>=')
      expect(dep4[:outdated]).to be_falsey

      dep5 = proj.projectdependencies[4]
      expect(dep5[:prod_key]).to eq(prod5[:prod_key])
      expect(dep5[:language]).to eq(prod5[:language])
      expect(dep5[:version_current]).to eq(prod5[:version])
      expect(dep5[:version_requested]).to eq('1.4.1')
      expect(dep5[:version_label]).to eq('1.4.1')
      expect(dep5[:comperator]).to eq('>=')
      expect(dep5[:outdated]).to be_falsey

      dep6 = proj.projectdependencies[5]
      expect(dep6[:prod_key]).to eq(prod6[:prod_key])
      expect(dep6[:language]).to eq(prod6[:language])
      expect(dep6[:version_current]).to eq(prod6[:version])
      expect(dep6[:version_requested]).to eq('3.4.4')
      expect(dep6[:version_label]).to eq('==3.4.4')
      expect(dep6[:comperator]).to eq('==')
      expect(dep6[:outdated]).to be_falsey

    end
  end
end
