class Repository < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  field :src     , type: String
  field :repotype, type: String

  embedded_in :product

  def as_json
    {
      :repo_source => self.src,
      :repo_type => self.repotype
    }
  end

  def to_s
    src
  end

  def self.name_for src
    return nil if src.to_s.strip.empty?
    return "Bintray JCenter" if src.to_s.match("jcenter\.bintray\.com")
    return "JFrog" if src.to_s.match("repo\.jfrog\.org")
    return "CarbonFive" if src.to_s.match("mvn\.carbonfive\.com")
    return "OSGeo Download Server" if src.to_s.match("download\.osgeo\.org")
    return "Gradle Artifactory" if src.to_s.match("gradle\.artifactoryonline\.com")
    return "Java.net" if src.to_s.match("download\.java\.net")
    return "Maven Central" if src.to_s.match("search\.maven\.org")
    return "JBoss" if src.to_s.match("repository\.jboss\.org")
    return "Ibiblio" if src.to_s.match("mirrors\.ibiblio\.org")
    return "MVN Search" if src.to_s.match("www\.mvnsearch\.org")
    return "MVN Search" if src.to_s.match("www\.mvnsearch\.org")
    return "Typesafe" if src.to_s.match("repo\.typesafe\.com")
    return "Clojars" if src.to_s.match("clojars\.org")
    return "Apache" if src.to_s.match("repo\.maven\.apache\.org")
    return "RubyGems" if src.to_s.match("rubygems\.org")
    return "PyPI" if src.to_s.match("pypi\.python\.org")
    return "NPM" if src.to_s.match("npmjs\.org")
    return src
  end

end
