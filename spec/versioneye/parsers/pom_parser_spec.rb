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

      product_11 = ProductFactory.create_for_maven("com.versioneye", "versioneye-core-j-1", "1.0.0")
      product_11.save
      product_11.add_version "0.9.0"
      product_11.save

      product_12 = ProductFactory.create_for_maven("com.versioneye", "versioneye-core-j-2", "1.0.0")
      product_12.save
      product_12.add_version "0.9.0"
      product_12.save

      product_13 = ProductFactory.create_for_maven("com.versioneye", "versioneye-core-j-3", "1.0.0")
      product_13.save
      product_13.add_version "0.9.0"
      product_13.save

      product_14 = ProductFactory.create_for_maven("com.versioneye", "versioneye-core-j-4", "1.0.0")
      product_14.save
      product_14.add_version "1.1.0"
      product_14.save

      product_15 = ProductFactory.create_for_maven("com.versioneye", "versioneye-core-j-5", "[1.0.0]")
      product_15.save
      product_15.add_version "1.1.0"
      product_15.save

      product_16 = ProductFactory.create_for_maven("com.versioneye", "versioneye-core-j-6", "1.0.0")
      product_16.save
      product_16.add_version "1.5.0"
      product_16.add_version "2.0.0"
      product_16.save

      product_17 = ProductFactory.create_for_maven("com.versioneye", "versioneye-core-j-7", "1.0.0")
      product_17.save
      product_17.add_version "1.5.0"
      product_17.add_version "2.0.0"
      product_17.save

      product_18 = ProductFactory.create_for_maven("com.versioneye", "versioneye-core-j-8", "1.0.0")
      product_18.save
      product_18.add_version "1.5.0"
      product_18.save

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

      dependency_10 = fetch_by_name project.dependencies, 'assertj-core'
      dependency_10.name.should eql("assertj-core")
      dependency_10.version_label.should eql('LATEST')
      dependency_10.version_requested.should eql("3.0.0-SNAPSHOT")
      dependency_10.version_current.should eql("2.0.0")
      dependency_10.comperator.should eql("=")
      dependency_10.outdated.should eql(false)
      dependency_10.scope.should eql("test")

      dependency_11 = fetch_by_name project.dependencies, 'versioneye-core-j-1'
      dependency_11.name.should eql("versioneye-core-j-1")
      dependency_11.version_label.should eql('(,1.0.0]')
      dependency_11.version_requested.should eql("1.0.0")
      dependency_11.version_current.should eql("1.0.0")
      dependency_11.comperator.should eql("<=")
      dependency_11.outdated.should eql(false)
      dependency_11.scope.should eql("compile")

      dependency_12 = fetch_by_name project.dependencies, 'versioneye-core-j-2'
      dependency_12.name.should eql("versioneye-core-j-2")
      dependency_12.version_label.should eql('(,1.0.0)')
      dependency_12.version_requested.should eql("0.9.0")
      dependency_12.version_current.should eql("1.0.0")
      dependency_12.comperator.should eql("<")
      dependency_12.outdated.should eql(true)
      dependency_12.scope.should eql("compile")

      dependency_14 = fetch_by_name project.dependencies, 'versioneye-core-j-3'
      dependency_14.name.should eql("versioneye-core-j-3")
      dependency_14.version_label.should eql('[1.0.0,)')
      dependency_14.version_requested.should eql("1.0.0")
      dependency_14.version_current.should eql("1.0.0")
      dependency_14.comperator.should eql(">=")
      dependency_14.outdated.should eql(false)
      dependency_14.scope.should eql("compile")

      dependency_15 = fetch_by_name project.dependencies, 'versioneye-core-j-4'
      dependency_15.name.should eql("versioneye-core-j-4")
      dependency_15.version_label.should eql('(1.0.0,)')
      dependency_15.version_requested.should eql("1.1.0")
      dependency_15.version_current.should eql("1.1.0")
      dependency_15.comperator.should eql(">")
      dependency_15.outdated.should eql(false)
      dependency_15.scope.should eql("compile")

      dependency_16 = fetch_by_name project.dependencies, 'versioneye-core-j-5'
      dependency_16.name.should eql("versioneye-core-j-5")
      dependency_16.version_label.should eql('[1.0.0]')
      dependency_16.version_requested.should eql("1.0.0")
      dependency_16.version_current.should eql("1.1.0")
      dependency_16.comperator.should eql("==")
      dependency_16.outdated.should eql(true)
      dependency_16.scope.should eql("compile")

      dependency_17 = fetch_by_name project.dependencies, 'versioneye-core-j-6'
      dependency_17.name.should eql("versioneye-core-j-6")
      dependency_17.version_label.should eql('[1.0.0,2.0.0]')
      dependency_17.version_requested.should eql("2.0.0")
      dependency_17.version_current.should eql("2.0.0")
      dependency_17.comperator.should eql("==")
      dependency_17.outdated.should eql(false)
      dependency_17.scope.should eql("compile")

      dependency_18 = fetch_by_name project.dependencies, 'versioneye-core-j-7'
      dependency_18.name.should eql("versioneye-core-j-7")
      dependency_18.version_label.should eql('[1.0.0,2.0.0)')
      dependency_18.version_requested.should eql("1.5.0")
      dependency_18.version_current.should eql("2.0.0")
      dependency_18.comperator.should eql("==")
      dependency_18.outdated.should eql(true)
      dependency_18.scope.should eql("compile")

      dependency_19 = fetch_by_name project.dependencies, 'versioneye-core-j-8'
      dependency_19.name.should eql("versioneye-core-j-8")
      dependency_19.version_label.should eql('(1.0.0,2.0.0]')
      dependency_19.version_requested.should eql("1.5.0")
      dependency_19.version_current.should eql("1.5.0")
      dependency_19.comperator.should eql("==")
      dependency_19.outdated.should eql(false)
      dependency_19.scope.should eql("compile")
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
