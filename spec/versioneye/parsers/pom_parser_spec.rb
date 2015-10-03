require 'spec_helper'

describe PomParser do

  describe "parse" do

    def fetch_by_name(dependencies, name)
      dependencies.each do |dep|
        return dep if dep.name.eql? name
      end
    end

    it "parse from https the file correctly" do
      parser = PomParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/pom.xml")
      project.should_not be_nil
    end

    it "parse the file correctly" do

      product_1 = ProductFactory.create_for_maven("junit", "junit", "4.4")
      product_1.save

      product_2 = ProductFactory.create_for_maven("commons-logging", "commons-logging", "1.1")
      product_2.save

      product_3 = ProductFactory.create_for_maven("commons-logging", "commons-logging-api", "1.1")
      product_3.save

      product_4 = ProductFactory.create_for_maven("log4j", "log4j", "1.2.15")
      product_4.save

      product_5 = ProductFactory.create_for_maven("javax.mail", "mail", "1.4")
      product_5.save

      product_6 = ProductFactory.create_for_maven("org.apache.commons", "commons-email", "1.4")
      product_6.save

      product_7 = ProductFactory.create_for_maven("org.apache.maven.plugins", "maven-project-info-reports-plugin", "1.0")
      product_7.save

      product_8 = ProductFactory.create_for_maven("org.apache.maven.plugins", "maven-surefire-report-plugin", "2.4.2")
      product_8.save

      product_9 = ProductFactory.create_for_maven("org.testng", "testng", "3.4")
      product_9.save
      product_9.add_version "4.0"
      product_9.add_version "4.5"
      product_9.add_version "5.0.0-SNAPSHOT"
      product_9.save

      product_10 = ProductFactory.create_for_maven("org.assertj", "assertj-core", "2.0.0")
      product_10.save
      product_10.add_version "1.0"
      product_10.add_version "1.5"
      product_10.add_version "3.0.0-SNAPSHOT"
      product_10.save

      parser = PomParser.new
      project = parser.parse("https://s3.amazonaws.com/veye_test_env/pom.xml")
      project.should_not be_nil

      dependency_01 = fetch_by_name project.dependencies, 'junit'
      dependency_01.name.should eql("junit")
      dependency_01.version_requested.should eql("4.4")
      dependency_01.version_current.should eql("4.4")
      dependency_01.comperator.should eql("=")
      dependency_01.scope.should eql(Dependency::A_SCOPE_TEST)

      dependency_02 = fetch_by_name project.dependencies, 'commons-logging'
      dependency_02.name.should eql("commons-logging")
      dependency_02.version_requested.should eql("1.1")
      dependency_02.version_current.should eql("1.1")
      dependency_02.comperator.should eql("=")
      dependency_02.scope.should eql("compile")

      dependency_03 = fetch_by_name project.dependencies, 'commons-logging-api'
      dependency_03.name.should eql("commons-logging-api")
      dependency_03.version_requested.should eql("1.1")
      dependency_03.version_current.should eql("1.1")
      dependency_03.comperator.should eql("=")
      dependency_03.scope.should eql("compile")

      dependency_04 = fetch_by_name project.dependencies, 'log4j'
      dependency_04.name.should eql("log4j")
      dependency_04.version_requested.should eql("1.2.15")
      dependency_04.version_current.should eql("1.2.15")
      dependency_04.comperator.should eql("=")
      dependency_04.scope.should eql("compile")

      dependency_05 = fetch_by_name project.dependencies, 'mail'
      dependency_05.name.should eql("mail")
      dependency_05.version_requested.should eql("1.4")
      dependency_05.version_current.should eql("1.4")
      dependency_05.comperator.should eql("=")
      dependency_05.scope.should eql("compile")

      dependency_06 = fetch_by_name project.dependencies, 'commons-email'
      dependency_06.name.should eql("commons-email")
      dependency_06.version_requested.should eql("1.2")
      dependency_06.version_current.should eql("1.4")
      dependency_06.comperator.should eql("=")
      dependency_06.scope.should eql("compile")

      dependency_07 = fetch_by_name project.dependencies, 'maven-project-info-reports-plugin'
      dependency_07.name.should eql("maven-project-info-reports-plugin")
      dependency_07.version_requested.should eql("1.0")
      dependency_07.version_current.should eql("1.0")
      dependency_07.comperator.should eql("=")
      dependency_07.scope.should eql("plugin")
      dependency_07.outdated.should eql(false)

      dependency_08 = fetch_by_name project.dependencies, 'maven-surefire-report-plugin'
      dependency_08.name.should eql("maven-surefire-report-plugin")
      dependency_08.group_id.should eql("org.apache.maven.plugins")
      dependency_08.version_requested.should eql("2.4.2")
      dependency_08.version_current.should eql("2.4.2")
      dependency_08.comperator.should eql("=")
      dependency_08.scope.should eql("plugin")
      dependency_08.outdated.should eql(false)

      dependency_09 = fetch_by_name project.dependencies, 'testng'
      dependency_09.name.should eql("testng")
      dependency_09.version_requested.should eql("4.5")
      dependency_09.version_current.should eql("4.5")
      dependency_09.comperator.should eql("=")
      dependency_09.scope.should eql("test")
      dependency_09.outdated.should eql(false)

      dependency_09 = fetch_by_name project.dependencies, 'assertj-core'
      dependency_09.name.should eql("assertj-core")
      dependency_09.version_label.should eql('LATEST')
      dependency_09.version_requested.should eql("3.0.0-SNAPSHOT")
      dependency_09.version_current.should eql("2.0.0")
      dependency_09.comperator.should eql("=")
      dependency_09.outdated.should eql(false)
      dependency_09.scope.should eql("test")
    end

  end

  describe "get_variable_value_from_pom" do

    it "returns val" do
      parser = PomParser.new
      properties = Hash.new
      parser.get_variable_value_from_pom(properties, "1.0").should eql("1.0")
    end

    it "returns still val" do
      properties = Hash.new
      properties["springVersion"] = "3.1"
      parser = PomParser.new
      parser.get_variable_value_from_pom(properties, "1.0").should eql("1.0")
    end

    it "returns value from the properties" do
      properties = Hash.new
      properties["springversion"] = "3.1"
      parser = PomParser.new
      parser.get_variable_value_from_pom(properties, "${springVersion}").should eql("3.1")
    end

    it "returns 3.1 because of downcase!" do
      properties = Hash.new
      properties["springversion"] = "3.1"
      parser = PomParser.new
      parser.get_variable_value_from_pom(properties, "${springVERSION}").should eql("3.1")
    end

    it "returns val because properties is empty" do
      parser = PomParser.new
      properties = Hash.new
      parser.get_variable_value_from_pom(properties, "${springVersion}").should eql("${springVersion}")
    end

  end

end
