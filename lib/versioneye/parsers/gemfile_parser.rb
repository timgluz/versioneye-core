require 'versioneye/parsers/common_parser'

class GemfileParser < CommonParser

  attr_accessor :language, :type, :keyword
  attr_reader :auth_token

  def language
    Product::A_LANGUAGE_RUBY
  end

  def type
    Project::A_TYPE_RUBYGEMS
  end

  def keyword
    'gem'
  end


  # Parser for Gemfile. For Ruby.
  # http://gembundler.com/man/gemfile.5.html
  # http://guides.rubygems.org/patterns/#semantic_versioning
  #
  def parse( url )
    return nil if url.nil? || url.empty?

    gemfile = fetch_response_body( url )
    return nil if gemfile.nil?

    parse_content( gemfile )
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def parse_content( gemfile, token = nil )
    return nil if gemfile.to_s.strip.empty?
    return nil if gemfile.to_s.strip.eql?('Not Found')

    @auth_token = token

    gemfile = gemfile.encode("UTF-8")
    project = init_project
    gemfile.each_line do |line|
      parse_line( line, project )
    end

    project.dep_number = project.dependencies.size
    update_project gemfile, project
    project
  rescue => e
    log.error "ERROR in parse_content(#{gemfile}) -> #{e.message}"
    log.error e.backtrace.join("\n")
    nil
  end

  def parse_line( line, project )
    return if line.to_s.empty?

    gem_doc = parse_gem_line(line.to_s)
    return if gem_doc.nil? # it wasnt dependency line

    gem_name = gem_doc[:name].to_s
    return nil if gem_name.empty?

    version    = fetch_version( gem_doc )
    product    = fetch_product_for gem_name
    dependency = init_dependency( product, gem_name )

    parse_requested_version( version, dependency, product )

    project.projectdependencies.push dependency
    project.out_number     += 1 if ProjectdependencyService.outdated?( dependency )
    project.unknown_number += 1 if product.nil?
  rescue => e
    log.error "ERROR in parse_line(#{line}) -> #{e.message}"
    log.error e.backtrace.join("\n")
    nil
  end


  def preprocess_line(gem_line)
    line = gem_line.to_s.strip

    if !line.valid_encoding?
      line = line.unpack('C*').pack('U*')
      line = line.encode('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')
    end
    line          = line.delete("\n")
    line          = line.delete("\t")

    line.to_s
  end

  # parses gem line and returns a hash map with parsed key-values
  # returns:
  #   dep_doc, Hashmap, with fields [:name, :version, :require, :git, :github, :branch, :tag, :ref, :branch, etc]
  #   nil if the gem_line is not dependency line
  def parse_gem_line(gem_line)
    line_items = fetch_line_elements(preprocess_line(gem_line)).to_a
    return if line_items.empty?

    gem_name = fetch_gem_name([line_items.shift]) # take and remove first item which maybe gem name
    return if gem_name.to_s.empty? # it wasnt dependeny line

    dep_doc = {
      name: gem_name,
      versions: []
    }

    line_items.reduce(dep_doc) do |acc, item|
      k, v = item.split(/\=\>|:\s+/, 2)
      if v.nil?
        # if no keyword were given, then it must be version label
        acc[:versions] << strip_quotes(k.to_s.strip)
      else
        # turn key into symbol and clean up value
        k = k.to_s.delete(':').strip.to_sym
        v = strip_quotes( v.to_s.strip )
        acc[k] = v
      end

      acc
    end

    dep_doc[:version] = dep_doc[:versions].to_a.join(',')
    dep_doc
  end


  # It is important that this method is not writing into the database!
  def parse_requested_version(version_number, dependency, product)
    if version_number.nil? || version_number.empty?
      self.update_requested_with_current(dependency, product)
      return
    end

    if product.nil?
      dependency.version_requested = version_number
      dependency.version_label     = version_number
      return
    end

    version = String.new( version_number )

    if version.match(/\A=/)
      # Equals
      version.gsub!('=', '')
      version.gsub!(' ', '')
      dependency.version_requested = version
      dependency.version_label     = version
      dependency.comperator        = '='

    elsif version.match(/\A!=/)
      # Not equal to version
      version.gsub!('!=', '')
      version.gsub!(' ', '')
      newest_version = VersionService.newest_but_not( product.versions, version)
      dependency.version_requested = newest_version
      dependency.comperator        = '!='
      dependency.version_label     = version

    elsif version.match(/\A>=/)
      # Greater than or equal to
      version.gsub!('>=', '')
      version.gsub!(' ', '')
      newest_version = VersionService.greater_than_or_equal( product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator        = '>='
      dependency.version_label     = version

    elsif version.match(/\A>/)
      # Greater than version
      version.gsub!('>', '')
      version.gsub!(' ', '')
      newest_version = VersionService.greater_than( product.versions, version )
      dependency.version_requested = newest_version.to_s
      dependency.comperator        = ">"
      dependency.version_label     = version

    elsif version.match(/\A<=/)
      # Less than or equal to
      version.gsub!("<=", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than_or_equal( product.versions, version )
      dependency.version_requested = newest_version.to_s
      dependency.comperator        = "<="
      dependency.version_label     = version

    elsif version.match(/\A\</)
      # Less than version
      version.gsub!("\<", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than( product.versions, version )
      dependency.version_requested = newest_version.to_s
      dependency.comperator        = "<"
      dependency.version_label     = version

    elsif version.match(/\A~>/)
      # Approximately greater than -> Pessimistic Version Constraint
      ver = version.gsub("~>", "")
      ver = ver.gsub(" ", "")
      starter         = VersionService.version_approximately_greater_than_starter( ver )
      versions        = VersionService.versions_start_with( product.versions, starter )
      highest_version = VersionService.newest_version_from( versions )
      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = ver
      end
      dependency.comperator = "~>"
      dependency.version_label = ver

    elsif version.match(/^git:/) or version.match(/\A:git/)
      #TODO: check is GITHUB url
      dependency.version_requested = "GIT"
      dependency.version_label     = "GIT"
      dependency.comperator        = "="

    elsif version.match(/^path:/) or version.match(/\A:path/)
      dependency.version_requested = "PATH"
      dependency.version_label     = "PATH"
      dependency.comperator        = "="

    else
      dependency.version_requested = version
      dependency.comperator        = "="
      dependency.version_label     = version
    end
  end


  # splits line into sub-items
  # it will keep list items as it is and
  # it removes leading spaces from each sub-item
  def fetch_line_elements( line, separator = ',' )
    line = replace_comments( line )
    line = line.to_s.strip

    tokens = []
    in_list = false
    token = ''
    line.each_char do |ch|
      if ch == separator and in_list == false
        token = token.strip
        tokens << token
        token = ''
      else
        token += ch
      end

      # update state machine
      if ch == '['
        in_list = true
      elsif ch == ']'
        in_list = false
      end

    end

    tokens << token.strip # the last left over
    tokens
  end

  def fetch_gem_name( line_elements )
    gem_name = line_elements.first
    return nil if gem_name.nil? || gem_name.empty?
    return nil if gem_name.match(/^#{keyword}\s+/).nil?
    gem_name.gsub!("#{keyword}", "")
    gem_name = gem_name.to_s.strip
    gem_name = gem_name.split(/\s+/).first

    strip_quotes(gem_name)
  end

  # gets version from parsed gemline doc
  # gemline doc is output of parse_gem_line('gem "pkg", "1.2.3"')
  # if it has github dependency, then it combines repo, ( branch or rev or tag ) as packages.json
  # returns:
  #   version_label, string
  def fetch_version( gem_doc )
    return "" if gem_doc.nil?
    return "" if gem_doc.is_a?(Hash) != true

    version = if gem_doc.fetch(:version, '').to_s.size > 0
                gem_doc[:version]
              elsif gem_doc.has_key?(:github)
                rev = (gem_doc[:rev] || gem_doc[:tag] || gem_doc[:branch])
                "#{gem_doc[:github]}##{rev}"
              elsif gem_doc.has_key?(:git)
                gem_doc[:git]
              elsif gem_doc.has_key?(:path)
                "path:#{gem_doc[:path]}"
              else
                gem_doc[:version]
              end


    #removes -x64,-x86, -mingw32 etc from version id
    version = strip_quotes(version)
    strip_platform_exts(version).to_s
  end


  def replace_comments( value )
    return nil unless value
    comment = value.match(/#.*/)
    if comment
      value.gsub!(comment[0], "")
    end
    value
  end


  def init_project( url = nil )
    project = Project.new
    project.project_type = type
    project.language     = language
    project.url          = url
    project
  end


  def init_dependency( product, gem_name )
    dependency          = Projectdependency.new
    dependency.name     = gem_name
    dependency.language = language
    if product
      dependency.name            = product.name
      dependency.language        = product.language
      dependency.prod_key        = product.prod_key
      dependency.version_current = product.version
    end
    dependency
  end


  def fetch_product_for key
    return nil if key.to_s.empty?
    if key.to_s.match(/\Arails-assets-/)
      new_key = key.gsub("rails-assets-", "")
      return Product.fetch_bower( new_key )
    else
      return Product.fetch_product( language, key )
    end
  rescue => e
    log.error "ERROR in fetch_product_for(#{key}) -> #{e.message}"
    log.error e.backtrace.join("\n")
    nil
  end


  def update_project gemfile, project
    gemfile.each_line do |line|
      if line.match(/\Aname /)
        project.name = line.gsub("name", "").gsub("\n", "").gsub("'", "").gsub("\"", "").strip
      elsif line.match(/\Aversion /)
        project.version = line.gsub("version", "").gsub("\n", "").gsub("'", "").gsub("\"", "").strip
      elsif line.match(/\Adescription /)
        project.description = line.gsub("description", "").gsub("\n", "").gsub("'", "").gsub("\"", "").strip
      elsif line.match(/\Alicense /)
        project.license = line.gsub("license", "").gsub("\n", "").gsub("'", "").gsub("\"", "").strip
      end
    end
    nil
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def strip_platform_exts(version)
    blacklist = Set.new ['x86', 'x64', 'java', 'mingw32'] #from nokogiri versions
    tokens = version.to_s.split('-')
    tokens = tokens.reduce([]) do |acc, tkn|
      unless blacklist.include? tkn.downcase
        #only add tokens that arenot in the blacklist
        acc << tkn
      end

      acc
    end

    tokens.join('-')
  end

  private

  def strip_quotes(version)
    version = version.gsub('"', '')
    version.gsub("'", '')
  end

  def gem_requirement?(requirement)
    begin
      requirement = strip_quotes(requirement)
      Gem::Requirement.parse(requirement)
      true
    rescue Gem::Requirement::BadRequirementError
      false
    end
  end

end
