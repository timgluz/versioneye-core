require 'versioneye/log'
require 'nokogiri'
require 'json'

class CommonParser

  def log
    Versioneye::Log.instance.log
  end

  def parse(url)
    raise NotImplementedError, 'Implement me in subclass!'
  end

  def from_json(json_doc, as_symbols = true)
    json_doc = json_doc.force_encoding(Encoding::UTF_8).strip
    json_doc = clean_spaces(json_doc) #replace non-ascii spaces with ascii spaces
    JSON.parse(json_doc, {symbolize_names: as_symbols})
  rescue => e
    log.error "from_json: failed to parse #{json_doc}"
    log.error e.backtrace.join('\n')
    return nil
  end


  SPECIAL_SPACES = [
    0x00A0,                # NO-BREAK SPACE
    0x1680,                # OGHAM SPACE MARK
    0x180E,                # MONGOLIAN VOWEL SEPARATOR
    (0x2000..0x200A).to_a, # EN QUAD..HAIR SPACE
    0x2028,                # LINE SEPARATOR
    0x2029,                # PARAGRAPH SEPARATOR
    0x202F,                # NARROW NO-BREAK SPACE
    0x205F,                # MEDIUM MATHEMATICAL SPACE
    0x3000,                # IDEOGRAPHIC SPACE
  ].flatten.collect{|e| [e].pack 'U*'}

  ZERO_WIDTH = [
    0x200B,                # ZERO WIDTH SPACE
    0x200C,                # ZERO WIDTH NON-JOINER
    0x200D,                # ZERO WIDTH JOINER
    0x2060,                # WORD JOINER
    0xFEFF,                # ZERO WIDTH NO-BREAK SPACE
  ].flatten.collect{|e| [e].pack 'U*'}

  def clean_spaces(txt)
    txt.gsub!(Regexp.new(ZERO_WIDTH.join("|")), "")
    txt.gsub!(Regexp.new(SPECIAL_SPACES.join("|") + "|\s"), " ")
    txt
  end
=begin

  One of this bothe methods needs to be implemented in each subclass.

  def parse_file(file_path)
    raise NotImplementedError, 'Implement me in subclass!'
  end

  def parse_content(content, token = nil)
    raise NotImplementedError, 'Implement me in subclass!'
  end
=end

  # It is important that this method is NOT writing into the database!
  #
  # Params:
  #   version           = the unparsed version string from the project file, e.g. '>= 2.0.1'
  #   projectdependency = This object can be empty/new. The results of the method are stored in this object
  #   product           = The corresponding product to the dependency. It can be nil if the dependency is unknown.
  #
  # Result: The method is parsing the version string and setting this values in projectdependency
  #   - projectdependency.version_label
  #   - projectdependency.version_requested
  #   - projectdependency.stability
  #   - projectdependency.comperator
  #
  def parse_requested_version(version, projectdependency, product)
    raise NotImplementedError, 'Implement me in subclass!'
  end

  def fetch_response url
    url = self.do_replacements_for_github url
    HttpService.fetch_response url
  rescue => e
    log.error "#{e.message} for #{url}"
    log.error e.backtrace.join("\n")
    nil
  end

  def fetch_response_body( url )
    response = self.fetch_response( url )
    response.body
  rescue => e
    log.error "#{e.message} for #{url}"
    log.error e.backtrace.join("\n")
    nil
  end

  def do_replacements_for_github(url)
    if url.match(/^https:\/\/github.com\//)
      url = url.gsub('https://github.com', 'https://raw.githubusercontent.com')
      url = url.gsub('/blob/', '/')
    end
    url
  end

  def update_requested_with_current( dependency, product )
    if product && product.version
      dependency.version_requested = VersionService.newest_version product.versions
    else
      dependency.version_requested = 'UNKNOWN'
    end
    #dependency.version_current = dependency.version_requested #TODO: should it update current version too?
    dependency
  end

  #TODO: it's should really be called as parse_xml and should handle parse error
  def fetch_xml( content )
    doc = Nokogiri::XML( content )
    return nil if doc.nil?

    doc.remove_namespaces!
    return nil if doc.nil?

    doc
  end


# -- helpers for file type matchers

  def self.rubygems_file?(filename)
    return true if /Gemfile\z/.match?(filename)
    return true if /Gemfile\.lock\z/.match?(filename)
    return true if /\w\.gemspec\z/.match?(filename)

    return false
  end

  def self.composer_file?(filename)
    return true if /composer\.json\z/.match?(filename)
    return true if /composer\.lock\z/.match?(filename)

    return false
  end

  def self.pip_file?(filename)
    return true if /requirements\.txt\z/.match?(filename)
    return true if /requirements\/.+\.txt/i.match?(filename)
    return true if /setup\.py\z/.match?(filename)
    return true if /pip\.log\z/.match?(filename)

    return false
  end

  def self.npm_file?(filename)
    return true if /package\.json\z/.match?(filename)
    return true if /yarn\.lock\z/i.match?(filename)
    return true if /npm-shrinkwrap\.json\z/.match?(filename)
    return true if /package-lock\.json\z/.match?(filename)

    return false
  end

  def self.gradle_file?(filename)
    return true if /\.gradle\z/.match?(filename)

    return false
  end

  def self.sbt_file?(filename)
    return true if /\.sbt\z/.match?(filename)

    return false
  end

  def self.maven_file?(filename)
    return true if /pom\.xml\z/.match?(filename)
    return true if /\.pom\z/.match?(filename)
    return true if /external_dependencies\.xml\z/.match?(filename)
    return true if /external-dependencies\.xml\z/.match?(filename)
    return true if /pom\.json\z/.match?(filename)

    return false
  end

  def self.lein_file?(filename)
    return true if /project\.clj\z/.match?(filename)

    return false
  end

  def self.bower_file?(filename)
    return true if /bower\.json\z/.match?(filename)

    return false
  end

  def self.biicode_file?(filename)
    return true if /biicode\.conf\z/.match?(filename)

    return false
  end

  def self.cocoapods_file?(filename)
    return true if /Podfile\z/.match?(filename)
    return true if /\.podfile\z/.match?(filename)
    return true if /Podfile\.lock\z/.match?(filename)

    return false
  end

  def self.chef_file?(filename)
    return true if /Berksfile\.lock\z/.match?(filename)
    return true if /Berksfile\z/.match?(filename)
    return true if /metadata\.rb\z/.match?(filename)

    return false
  end

  def self.nuget_file?(filename)
    return true if /project\.json\z/.match?(filename)
    return true if /.*\.nuspec\z/.match?(filename)
    return true if /packages\.config\z/.match?(filename)
    return true if /.*\.csproj\z/.match?(filename)

    return false
  end

  def self.cpan_file?(filename)
    return true if /cpanfile\z/i.match?(filename)

    return false
  end

  def self.cargo_file?(filename)
    return true if /Cargo\.toml\z/i.match?(filename)
    return true if /Cargo\.lock\z/i.match?(filename)

    return false
  end

  def self.hex_file?(filename)
    return true if /\bmix\.exs\z/i.match?(filename)
    return true if /rebar\.config\z/i.match?(filename)
    return true if /erlang\.mk\z/i.match?(filename)

    return false
  end
end

