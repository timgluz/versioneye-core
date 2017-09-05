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


end
