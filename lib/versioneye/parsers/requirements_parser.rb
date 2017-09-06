require 'uri'
require 'versioneye/parsers/common_parser'

# Parser for requirements.txt files from pip. Python.
# http://www.pip-installer.org/en/latest/requirements.html#the-requirements-file-format
# http://www.pip-installer.org/en/latest/#requirements-files
#
# it will resolve state of GITHUB dependency, only if you set token with valid GH token

class RequirementsParser < CommonParser
  attr_reader :auth_token

  def parse( url, token = nil )
    return nil if url.nil?
    @auth_token = token

    response = self.fetch_response(url)
    return nil if response.nil?
    return nil if response.code.to_i != 200 && response.code.to_i != 201

    parse_content response.body
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def parse_content( txt, token = nil )
    @auth_token = token if token

    txt = txt.to_s.strip
    return nil if txt.empty?
    return nil if txt.eql?('Not Found')

    project = Project.new(
      project_type: Project::A_TYPE_PIP,
      language: Product::A_LANGUAGE_PYTHON
    )

    txt.each_line do |line|
      parse_line line, project
    end

    project.dep_number = project.dependencies.size

    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  def parse_line( line, project )
    dep_line = line.to_s.strip
    return false if dep_line.empty?
    return false if /\A\#/.match?(dep_line) # if it is line comment
    return false if /\A\-r\s*/.match?(dep_line) # ignore recursive deps file

    dep_line = if scm_line?(dep_line)
                 process_scm_line(dep_line) # turns scm req into pip req
               else
                 line.split("#", 2).to_a.first # Remove comments at the end
               end
    return false if dep_line.nil? || dep_line.empty?

    comparator  = extract_comparator dep_line
    requirement = dep_line.split(comparator, 2) # it should have only 1 comperator

    package     = extract_name requirement
    if package.nil? || package.strip.empty?
      log.error "parse_line: dependency line includes no package name: `#{line}`"
      return false
    end

    return false if package.match(/\Ahttp:\/\//)
    return false if package.match(/\Ahttps:\/\//)
    return false if package.match(/\A--/)


    # process version label
    version = ''
    if requirement.count > 1
      version = requirement[1]
      version = version.gsub("\n", '')
      version = version.gsub("\\", '')
      version = version.gsub(/--hash.+\z/i, '') # ignore hash values
      version = version.to_s.strip
    end

    product = Product.fetch_product Product::A_LANGUAGE_PYTHON, package
    if product.nil? && package.match(/-/)
      product = Product.fetch_product Product::A_LANGUAGE_PYTHON, package.gsub("-", "_")
    end

    dependency = init_dependency product, package, comparator
    dependency.version_label = version
    parse_requested_version("#{comparator}#{version}", dependency, product)

    is_outdated = ProjectdependencyService.outdated?(dependency, product, @auth_token)
    project.out_number     += 1 if is_outdated
    project.unknown_number += 1 if product.nil?
    project.projectdependencies.push dependency

    project
  end


  # It is important that this method is not writing int the database!
  #
  def parse_requested_version(version, dependency, product)
    if version.nil? || version.empty?
      dependency[:comperator] = '>='
      self.update_requested_with_current(dependency, product)
      return
    end

    version = version.strip
    version = version.gsub('"', '')
    version = version.gsub("'", '').to_s.strip
    dependency.version_label = String.new(version)

    if product.nil?
      log.warn "parse_requested_version: no product for `#{dependency}`"
      dependency.version_requested = 'UNKNOWN'
      return nil
    end

    if version.match(/,/)
      # Version Ranges
      highest_version = VersionService.from_common_range(product.versions, version, false, ',')

      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = version
      end
      dependency.comperator = "="


    elsif version.match(/\.\*\z/)
      # WildCards. 1.0.* => 1.0.0 | 1.0.2 | 1.0.20
      ver = version.gsub("*", "")
      ver = ver.gsub(/\s+/, "").to_s.strip

      highest_version = VersionService.newest_version_from_wildcard( product.versions, ver, dependency.stability )
      if highest_version
        dependency.version_requested = highest_version
      else
        dependency.version_requested = version
      end
      dependency.comperator = "="

    elsif version.match(/\A\*\z/)
      latest_version = VersionService.newest_version_number( product.versions, dependency.stability )

      dependency.version_requested = latest_version.to_s
      dependency.version_label = "*"
      dependency.comperator = ">="

    elsif version.match(/\=\=/)
      # Equals
      version.gsub!(/\A\=\=/, "")
      version.gsub!(" ", "")

      dependency.version_requested = version.strip
      dependency.comperator = "=="
      add_scm_details(dependency, version)

      dependency
    elsif version.match(/\A!=/)
      # Not equal to version
      version.gsub!("!=", "")
      version.gsub!(" ", "")
      newest_version = VersionService.newest_but_not(product.versions, version)
      dependency.version_requested = newest_version
      dependency.comperator = "!="

    elsif version.match(/\A>=/)
      # Greater than or equal to
      version.gsub!(">=", "")
      version.gsub!(" ", "")
      newest_version = VersionService.greater_than_or_equal(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = ">="

    elsif version.match(/\A>/)
      # Greater than version
      version.gsub!(">", "")
      version.gsub!(" ", "")
      newest_version = VersionService.greater_than(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = ">"

    elsif version.match(/\A<=/)
      # Less than or equal to
      version.gsub!("<=", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than_or_equal(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = "<="

    elsif version.match(/\A\</)
      # Less than version
      version.gsub!("<", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = "<"

    else
      dependency.version_requested = version
      dependency.comperator = "=="
    end

  end

  def add_scm_details(dependency, version)
    return if /\A\d/.match?(version) # ignore if version starts with number == not SCM url

    scm_type = case version
               when /\Agit[:|\+]/i then 'GIT'
               when /\Ahg[:|\+]/i then 'HG'
               when /\Abzr[:|\+]/i then 'BZR'
               when /\w\/\w/ then 'GITHUB'
               else 'UNKNOWN'
               end

    dependency[:version_requested] = scm_type
    if scm_type == 'GITHUB'
      repo_name, repo_ref = version.split('#', 2)
      repo_ref ||= 'master'

      dependency[:repo_fullname] = repo_name.to_s.strip
      dependency[:repo_ref]      = repo_ref.to_s.strip
    end
  end

  # processes requirements from SCM (git, hg, bzr) to like PIP line, except GH deps
  #
  # For Github dependencies it returns similar format as NPM github dep,
  # so it GithubComperator could pick it up and check it against latest version
  #
  # for other SCM it just retuns PIP-like format: EGG-NAMe==scm_value
  # so these packages doesnt get lost and user can still see them
  #
  # returns:
  #  pip_line - String format EGG_NAME=NPM_GH_FORMAT|SCM_STRING
  #  nil - if parsing failed for some reason
  def process_scm_line(scm_line)
    scm_line = scm_line.to_s.strip.gsub(/^\[?\-\w\]?\s+/, '') # remove prefix -r/-e
    scm_url = parse_url(scm_line)


    # extract Egg's name from URL fragment
    egg = extract_egg_name(scm_url)
    if egg.empty?
      log.error "process_scm_line: scm line misses egg name: #{scm_line}"
      return
    end

    # extract SCM revision, it can be either before Egg name or after
    scm_path, rev = extract_scm_details(scm_url)

    # build dep string from SCM
    # NB! it ignores user logins in the url, so it wouldnt expose outside
    # example url: bzr+ftp://user@myproject.org/MyProject/trunk/#egg=MyProject
    scm_url_txt = scm_url.scheme + '://' + scm_url.host + scm_path
    if github_url?(scm_url_txt)
      repo_name = extract_git_fullname(scm_url_txt)
      scm_url_txt = repo_name if repo_name.nil? == false
    end

    format_scm_dep egg, scm_url_txt, rev
  end

  def format_scm_dep(pkg_name, scm_url, rev = nil)
    if rev.to_s.empty?
      "#{pkg_name}==#{scm_url}"
    else
      "#{pkg_name}==#{scm_url}##{rev}"
    end
  end

  def extract_egg_name(scm_url)
    return "" unless scm_url.is_a?(URI)

    scm_url.fragment.to_s.gsub(/\Aegg\=/, '').to_s.strip
  end

  def github_url?(scm_url)
    /github\.com/.match?(scm_url.to_s.strip)
  end

  def scm_line?(scm_line)
    return false if scm_line.is_a?(String) == false

    return /^(\[?-?\w?\]?\s+)?(git|bzr|hg|svn)/i.match?(scm_line)
  end

  def init_dependency( product, package_name, comperator = '==')
    dependency = Projectdependency.new(
      name: package_name,
      language: Product::A_LANGUAGE_PYTHON,
      comperator: comperator,
      scope: Dependency::A_SCOPE_COMPILE
    )

    if product
      dependency.prod_key = product.prod_key
      dependency.version_current = product.version
    end

    dependency
  end

  def extract_scm_details(scm_url)
    rev = nil
    scm_path = scm_url.path.to_s

    # remove revision details from the path
    if scm_path.rindex(/\w\@?/)
      scm_path, rev = scm_path.split(/\@/, 2)
    end
    scm_path = scm_path.gsub(/\/\z/, '').to_s.strip

    [scm_path, rev]
  end

  def parse_url(scm_url)
    URI.parse scm_url
  rescue => e
    log.error "parse_url: failed to parse SCM url `#{scm_url}`"
    log.error "\treason: #{e.message}"
    nil
  end

  # extracts repo owner and name from long GIT url and returns repo fullname
  # ps: it expects URL string as parameters and not line from requirements.txt
  def extract_git_fullname(scm_url)
    u = URI.parse(scm_url)
    path = u.path.to_s.gsub(/\.git.*\z/, '').to_s

    # ignore empty tokens then join next 2 non-empty strings ones together
    path.split(/\//).reject {|tkn| tkn.empty? }.take(2).join('/')
  rescue
    log.error "extract_repo_name: failed to parse `#{scm_url}` as url"
    nil
  end


  def extract_name requirement
    package = requirement[0].to_s.strip
    if package.match(/.+\[(.+)\]/i) # for example: prospector[with_pyroma,with_vulture]
      package = package.gsub(/\[.+\]/, "") # replace the brackets
    end

    package
  end

  def extract_comparator line
    case line
    when />=/ then '>='
    when />/  then '>'
    when /<=/ then '<='
    when /</  then '<'
    when /!=/ then '!='
    when /==/ then '=='
    else
      nil
    end
  end

end
