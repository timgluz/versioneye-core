require 'spec_helper'
require 'cocoapods-core'

describe ParserStrategy do

  describe "parser_for" do

    it "returns GemfileParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_RUBYGEMS, "Gemfile" )
      expect( parser.is_a?( GemfileParser ) ).to be_truthy
    end

    it "returns GemspecParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_RUBYGEMS, 'veye.gemspec')
      expect( parser.is_a?( GemspecParser ) ).to be_truthy
    end

    it "returns GemfilelockParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_RUBYGEMS, "Gemfile.lock" )
      expect( parser.is_a?( GemfilelockParser ) ).to be_truthy
    end

    it "returns ComposerParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_COMPOSER, "composer.json" )
      expect( parser.is_a?( ComposerParser ) ).to be_truthy
    end

    it "returns ComposerLockParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_COMPOSER, "composer.lock" )
      expect( parser.is_a?( ComposerLockParser ) ).to be_truthy
    end

    it "returns PodfilelockParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_COCOAPODS, "Podfile.lock" )
      expect( parser.is_a?( PodfilelockParser ) ).to be_truthy
    end

    it "returns PodfileParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_COCOAPODS, "Podfile" )
      expect( parser.is_a?( PodfileParser ) ).to be_truthy
    end

    it "returns PomParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_MAVEN2, "pom.xml" )
      expect( parser.is_a?( PomParser ) ).to be_truthy
    end

    it "returns PomParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_MAVEN2, "pom.json" )
      expect( parser.is_a?( PomJsonParser ) ).to be_truthy
    end

    it "returns BowerParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_BOWER, "bower.json" )
      expect( parser.is_a?( BowerParser ) ).to be_truthy
    end

    it "returns RequirementsParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_PIP, "requirements.txt" )
      expect( parser.is_a?( RequirementsParser ) ).to be_truthy
    end

    it "returns PythonSetupParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_PIP, "setup.py" )
      expect( parser.is_a?( PythonSetupParser ) ).to be_truthy
    end

    it "returns PackageParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_NPM, "package.json" )
      expect( parser.is_a?( PackageParser ) ).to be_truthy
    end

    it "returns GradleParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_GRADLE, "dep.gradle" )
      expect( parser.is_a?( GradleParser ) ).to be_truthy
    end

    it "returns LeinParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_LEIN, "lein" )
      expect( parser.is_a?( LeinParser ) ).to be_truthy
    end

    it "returns NugetJSONParser" do
      parser = ParserStrategy.parser_for( Project::A_TYPE_NUGET, "http://s3.aws.com/project.json")
      expect( parser.is_a?(NugetJsonParser) ).to be_truthy
    end

    it "returns NugetPackagesParser" do
      parser = ParserStrategy.parser_for(Project::A_TYPE_NUGET, "http://s3.aws.com/packages.config")
      expect( parser.is_a?(NugetPackagesParser) ).to be_truthy
    end

    it "return CsprojParser" do
      parser = ParserStrategy.parser_for(Project::A_TYPE_NUGET, 'veye.csproj')
      expect( parser.is_a?(CsprojParser) ).to be_truthy
    end

    it "returns NugetParser" do
      parser = ParserStrategy.parser_for(Project::A_TYPE_NUGET, "http://s3.aws.com/project.nuspec")
      expect( parser.is_a?(NugetParser) ).to be_truthy
    end

    it "returns GodepParser" do
      parser = ParserStrategy.parser_for(Project::A_TYPE_GODEP, 'Godeps.json')
      expect( parser.is_a?(GodepParser) ).to be_truthy
    end

    it "returns CpanParser" do
      parser = ParserStrategy.parser_for(Project::A_TYPE_CPAN, "cpan")
      expect( parser.is_a?(CpanParser) ).to be_truthy
    end

    it "returns YarnParser" do
      parser = ParserStrategy.parser_for(Project::A_TYPE_NPM, 'yarn.lock')
      expect( parser.is_a?(YarnParser) ).to be_truthy
    end

    it "returns ShrinkwrapParser" do
      parser = ParserStrategy.parser_for(Project::A_TYPE_NPM, 'npm-shrinkwrap.json')
      expect( parser.is_a?(ShrinkwrapParser) ).to be_truthy
    end

    it "returns PackageLockParser" do
      parser = ParserStrategy.parser_for(Project::A_TYPE_NPM, 'package-lock.json')
      expect( parser.is_a?(PackageLockParser) ).to be_truthy
    end

    it "returns CargoParser" do
      parser = ParserStrategy.parser_for(Project::A_TYPE_CARGO, 'Cargo.toml')
      expect( parser.is_a?(CargoParser) ).to be_truthy
    end

    it "returns CargoLockParser" do
      parser = ParserStrategy.parser_for(Project::A_TYPE_CARGO, 'Cargo.lock')
      expect( parser.is_a?(CargoLockParser) ).to be_truthy
    end

    it "returns MixParser" do
      parser = ParserStrategy.parser_for(Project::A_TYPE_HEX, 'mix.exs')
      expect( parser.is_a?(MixParser) ).to be_truthy
    end

    it "returns nil" do
      parser = ParserStrategy.parser_for( "HujBuy", "lein" )
      expect( parser ).to be_nil
    end

  end

end
