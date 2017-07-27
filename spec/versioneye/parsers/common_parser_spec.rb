require 'spec_helper'

describe CommonParser do
  context "file type matchers" do

    it "has matches for rubygems" do
      expect(CommonParser.rubygems_file?("Gemfile")).to be_truthy
      expect(CommonParser.rubygems_file?("/a/b/Gemfile")).to be_truthy
      expect(CommonParser.rubygems_file?("Gemfile.lock")).to be_truthy
      expect(CommonParser.rubygems_file?("veye.gemspec")).to be_truthy
    end

    it "doesnt found matches for rubygems" do
      expect(CommonParser.rubygems_file?('Gemfiles')).to be_falsey
      expect(CommonParser.rubygems_file?('gemspec/java.pom')).to be_falsey
      expect(CommonParser.rubygems_file?('/a/b/gemspec')).to be_falsey
      expect(CommonParser.rubygems_file?('folder_gemspec')).to be_falsey
    end

    it "has matches for composer files" do
      expect(CommonParser.composer_file?('composer.json')).to be_truthy
      expect(CommonParser.composer_file?('/a/b/composer.json')).to be_truthy
      expect(CommonParser.composer_file?('composer.lock')).to be_truthy
      expect(CommonParser.composer_file?('/a/b/composer.lock')).to be_truthy
    end

    it "has no matches for composer files" do
      expect(CommonParser.composer_file?('composer.json.backup')).to be_falsey
      expect(CommonParser.composer_file?('composer?lock')).to be_falsey
    end

    it "has matches for all PyPi files" do
      expect(CommonParser.pip_file?('requirements.txt')).to be_truthy
      expect(CommonParser.pip_file?('/a/b/requirements.txt')).to be_truthy
      expect(CommonParser.pip_file?('requirements/pip.txt')).to be_truthy
      expect(CommonParser.pip_file?('setup.py')).to be_truthy
      expect(CommonParser.pip_file?('/a/b/setup.py')).to be_truthy
      expect(CommonParser.pip_file?('pip.log')).to be_truthy
    end

    it "has no matches to Pypi like garbage" do
      expect(CommonParser.pip_file?('requirements_txt')).to be_falsey
      expect(CommonParser.pip_file?('setup_py')).to be_falsey
      expect(CommonParser.pip_file?('pip_log')).to be_falsey
    end

    it "matches with NPM files" do
      expect(CommonParser.npm_file?('package.json')).to be_truthy
      expect(CommonParser.npm_file?('/a/b/package.json')).to be_truthy
      expect(CommonParser.npm_file?('yarn.lock')).to be_truthy
      expect(CommonParser.npm_file?('a/b/yarn.lock')).to be_truthy
      expect(CommonParser.npm_file?('npm-shrinkwrap.json')).to be_truthy
      expect(CommonParser.npm_file?('/a/b/npm-shrinkwrap.json')).to be_truthy
      expect(CommonParser.npm_file?('package-lock.json')).to be_truthy
      expect(CommonParser.npm_file?('/a/b/package-lock.json')).to be_truthy
    end

    it "misses NPM like garbage" do
      expect(CommonParser.npm_file?('package/json')).to be_falsey
      expect(CommonParser.npm_file?('yarn/lock')).to be_falsey
      expect(CommonParser.npm_file?('npm-shrinkwrap/json')).to be_falsey
      expect(CommonParser.npm_file?('package.lock.json')).to be_falsey
    end

    it "matches with Gradle files" do
      expect(CommonParser.gradle_file?('veye.gradle')).to be_truthy
      expect(CommonParser.gradle_file?('/a/b/veye.gradle')).to be_truthy
    end

    it "misses Gradle like garbage" do
      expect(CommonParser.gradle_file?('_gradle')).to be_falsey
      expect(CommonParser.gradle_file?('/gradle/pom.xml')).to be_falsey
    end

    it "matches with SBT files" do
      expect(CommonParser.sbt_file?('project.sbt')).to be_truthy
      expect(CommonParser.sbt_file?('/a/b/veye.sbt')).to be_truthy
    end

    it "misses SBT like garbage" do
      expect(CommonParser.sbt_file?('asbt')).to be_falsey
      expect(CommonParser.sbt_file?('/sbt')).to be_falsey
    end

    it "matches with Maven2 files" do
      expect(CommonParser.maven_file?('pom.xml')).to be_truthy
      expect(CommonParser.maven_file?('/a/b/pom.xml')).to be_truthy
      expect(CommonParser.maven_file?('veye.pom')).to be_truthy
      expect(CommonParser.maven_file?('/a/b/veye.pom')).to be_truthy
      expect(CommonParser.maven_file?('external_dependencies.xml')).to be_truthy
      expect(CommonParser.maven_file?('/a/b/external_dependencies.xml')).to be_truthy
      expect(CommonParser.maven_file?('external-dependencies.xml')).to be_truthy
    end

    it "misses Maven2 looking filenames" do
      expect(CommonParser.maven_file?('pom_xml')).to be_falsey
      expect(CommonParser.maven_file?('veye/pom')).to be_falsey
      expect(CommonParser.maven_file?('external_dependencies_xml')).to be_falsey
      expect(CommonParser.maven_file?('a/pom/json')).to be_falsey
    end

    it "matches with Leiningen files" do
      expect(CommonParser.lein_file?('project.clj')).to be_truthy
      expect(CommonParser.lein_file?('/a/b/project.clj')).to be_truthy
    end

    it "misses Leiningen looking filenames" do
      expect(CommonParser.lein_file?('project_clj')).to be_falsey
      expect(CommonParser.lein_file?('project/clj')).to be_falsey
    end

    it "matches with Bower files" do
      expect(CommonParser.bower_file?('bower.json') ).to be_truthy
      expect(CommonParser.bower_file?('/a/b/bower.json')).to be_truthy
    end

    it "misses Bower looking filenames" do
      expect(CommonParser.bower_file?('bower/json')).to be_falsey
      expect(CommonParser.bower_file?('/a/bower.json/b')).to be_falsey
    end

    it "matches with Biicode files" do
      expect(CommonParser.biicode_file?('biicode.conf')).to be_truthy
      expect(CommonParser.biicode_file?('/a/b/biicode.conf')).to be_truthy
    end

    it "misses Biicode looking filenames" do
      expect(CommonParser.biicode_file?('biicode/conf')).to be_falsey
      expect(CommonParser.biicode_file?('/a/biicode/conf/z')).to be_falsey
    end

    it "matches with Cocoapods files" do
      expect(CommonParser.cocoapods_file?('Podfile')).to be_truthy
      expect(CommonParser.cocoapods_file?('/a/b/Podfile')).to be_truthy
      expect(CommonParser.cocoapods_file?('veye.podfile')).to be_truthy
      expect(CommonParser.cocoapods_file?('/a/b/veye.podfile')).to be_truthy
      expect(CommonParser.cocoapods_file?('Podfile.lock')).to be_truthy
      expect(CommonParser.cocoapods_file?('/a/b/Podfile.lock')).to be_truthy
    end

    it "misses Cocoapods looking filenames" do
      expect(CommonParser.cocoapods_file?('Podfile/a/b')).to be_falsey
      expect(CommonParser.cocoapods_file?('veye/podfile')).to be_falsey
      expect(CommonParser.cocoapods_file?('Podfile/lock')).to be_falsey
    end

    it "matches with Chef files" do
      expect(CommonParser.chef_file?('Berksfile')).to be_truthy
      expect(CommonParser.chef_file?('/a/b/Berksfile')).to be_truthy
      expect(CommonParser.chef_file?('Berksfile.lock')).to be_truthy
      expect(CommonParser.chef_file?('/a/b/Berksfile.lock')).to be_truthy
      expect(CommonParser.chef_file?('metadata.rb')).to be_truthy
      expect(CommonParser.chef_file?('/a/b/metadata.rb')).to be_truthy
    end

    it "misses Chef looking filenames" do
      expect(CommonParser.chef_file?('Berksfile/a')).to be_falsey
      expect(CommonParser.chef_file?('Berksfile/lock')).to be_falsey
      expect(CommonParser.chef_file?('metadata/rb')).to be_falsey
    end

    it "matches Nuget filenames" do
      expect(CommonParser.nuget_file?('project.json')).to be_truthy
      expect(CommonParser.nuget_file?('/a/b/project.json')).to be_truthy
      expect(CommonParser.nuget_file?('veye.nuspec')).to be_truthy
      expect(CommonParser.nuget_file?('/a/b/veye.nuspec')).to be_truthy
      expect(CommonParser.nuget_file?('packages.config')).to be_truthy
      expect(CommonParser.nuget_file?('/a/b/packages.config')).to be_truthy
      expect(CommonParser.nuget_file?('veye.csproj')).to be_truthy
      expect(CommonParser.nuget_file?('/a/b/veye.csproj')).to be_truthy
    end

    it "misses Nuget looking filenames" do
      expect(CommonParser.nuget_file?('project/json')).to be_falsey
      expect(CommonParser.nuget_file?('veye/nuspec')).to be_falsey
      expect(CommonParser.nuget_file?('packages/config')).to be_falsey
      expect(CommonParser.nuget_file?('veye/csproj')).to be_falsey
    end

    it "matches Cpan filenames" do
      expect(CommonParser.cpan_file?('Cpanfile')).to be_truthy
      expect(CommonParser.cpan_file?('/a/b/cpanfile')).to be_truthy
      expect(CommonParser.cpan_file?('META.json')).to be_truthy
      expect(CommonParser.cpan_file?('/a/b/META.json')).to be_truthy
      expect(CommonParser.cpan_file?('META.yml')).to be_truthy
      expect(CommonParser.cpan_file?('/a/b/META.yml')).to be_truthy
    end

    it "misses Cpan looking filenames" do
      expect(CommonParser.cpan_file?('cpanfile/a/b')).to be_falsey
    end

    it "matches Cargo filenames" do
      expect(CommonParser.cargo_file?('Cargo.toml')).to be_truthy
      expect(CommonParser.cargo_file?('/a/b/Cargo.toml')).to be_truthy
      expect(CommonParser.cargo_file?('Cargo.lock')).to be_truthy
      expect(CommonParser.cargo_file?('/a/b/Cargo.lock')).to be_truthy
    end

    it "misses Cargo looking filenames" do
      expect(CommonParser.cargo_file?('cargo/toml')).to be_falsey
      expect(CommonParser.cargo_file?('cargo/lock')).to be_falsey
    end

    it "matches Hex filenames" do
      expect(CommonParser.hex_file?('mix.exs') ).to be_truthy
      expect(CommonParser.hex_file?('/a/b/mix.exs')).to be_truthy
    end

    it "misses Hex looking filenames" do
      expect(CommonParser.hex_file?('mix/exs')).to be_falsey
      expect(CommonParser.hex_file?('remix.exs')).to be_falsey
    end
  end
end
