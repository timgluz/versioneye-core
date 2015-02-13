require 'versioneye/parsers/common_parser'
require 'semverly'

class PackageParser < CommonParser

  # Parser for requirements.json from npm. NodeJS
  # https://github.com/isaacs/node-semver
  # https://npmjs.org/doc/json.html
  # http://wiki.commonjs.org/wiki/Packages/1.1
  #
  def parse ( url )
    return nil if url.to_s.empty?

    body = self.fetch_response_body( url )
    parse_content body
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  
  def parse_content( content )
    data = JSON.parse( content )
    return nil if data.nil?

    project = init_project( data )
    
    dependencies = data['dependencies']
    if dependencies && !dependencies.empty?
      parse_dependencies dependencies, project
    end

    dev_dependencies = data['devDependencies']
    if dev_dependencies && !dev_dependencies.empty?
      parse_dependencies dev_dependencies, project, Dependency::A_SCOPE_DEVELOPMENT
    end

    bundledDependencies = data['bundledDependencies']
    if bundledDependencies && !bundledDependencies.empty?
      parse_dependencies bundledDependencies, project, Dependency::A_SCOPE_BUNDLED
    end

    optionalDependencies = data['optionalDependencies']
    if optionalDependencies && !optionalDependencies.empty?
      parse_dependencies optionalDependencies, project, Dependency::A_SCOPE_OPTIONAL
    end

    project.dep_number = project.dependencies.size
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def parse_dependencies dependencies, project, scope = Dependency::A_SCOPE_COMPILE
    dependencies.each do |package_name, version_label|
      parse_line( package_name, version_label, project, scope )
    end
  end


  def parse_line( package_name, version_label, project, scope = Dependency::A_SCOPE_COMPILE )
    product    = Product.fetch_product( Product::A_LANGUAGE_NODEJS, package_name )
    dependency = init_dependency( product, package_name )
    dependency.scope = scope 
    parse_requested_version( version_label, dependency, product )
    project.out_number     += 1 if ProjectdependencyService.outdated?( dependency )
    project.unknown_number += 1 if product.nil?
    project.projectdependencies.push dependency
  end

  
  # It is important that this method is not writing int the database!
  #
  def parse_requested_version(version, dependency, product)
    if version.to_s.strip.empty?
      self.update_requested_with_current(dependency, product)
      return
    end

    version = version.to_s.strip
    version = version.gsub('"', '')
    version = version.gsub("'", '')
    version = version.gsub(/x\.x/i, "x")
    if version.match(/\Av\d.*/)
      version = version[1..version.length]
    end


    if product.nil?
      dependency.version_requested = version
      dependency.version_label     = version
      return
    end

    version = pre_process version

    if version.match(/\|\|/)
      parsed_versions = []
      versions = version.split("||")
      versions.each do |verso|
        proj_dep = init_dependency product, dependency.name
        parse_requested_version verso, proj_dep, product
        parsed_versions << proj_dep.version_requested
      end
      highest_version = VersionService.newest_version_from( parsed_versions )
      dependency.version_requested = highest_version
      dependency.version_label = version
      dependency.comperator = '||'

    elsif version.match(/\A\*\z/)
      # Start Matching. Matches everything.
      dependency.version_requested = product.version
      dependency.version_label = '*'
      dependency.comperator = '='

    elsif version.match(/\A\*\z/)
      # Start Matching. Matches everything.
      dependency.version_requested = product.version
      dependency.version_label = 'X'
      dependency.comperator = '='

    elsif version.casecmp('latest') == 0
      # Start Matching. Matches everything.
      dependency.version_requested = product.version
      dependency.version_label = 'latest'
      dependency.comperator = '='

    elsif version.match(/\A=/)
      # Equals
      version.gsub!('=', '')
      version.gsub!(' ', '')
      dependency.version_requested = version
      dependency.version_label = version
      dependency.comperator = '='

    elsif version.match(/\A!=/)
      # Not equal to version
      version.gsub!('!=', '')
      version.gsub!(' ', '')
      newest_version = VersionService.newest_but_not(product.versions, version)
      dependency.version_requested = newest_version
      dependency.comperator = '!='
      dependency.version_label = version

    elsif version.match(/\A>=/)
      # Greater than or equal to
      version.gsub!('>=', '')
      version.gsub!(' ', '')
      newest_version = VersionService.greater_than_or_equal(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = '>='
      dependency.version_label = version

    elsif version.match(/\A>/)
      # Greater than version
      version.gsub!('>', '')
      version.gsub!(' ', '')
      newest_version = VersionService.greater_than(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = ">"
      dependency.version_label = version

    elsif version.match(/\A<=/)
      # Less than or equal to
      version.gsub!("<=", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than_or_equal(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = "<="
      dependency.version_label = version

    elsif version.match(/\A\</)
      # Less than version
      version.gsub!("\<", "")
      version.gsub!(" ", "")
      newest_version = VersionService.smaller_than(product.versions, version)
      dependency.version_requested = newest_version.to_s
      dependency.comperator = "<"
      dependency.version_label = version

    elsif version.match(/\A~/)
      # Tilde Version Ranges -> Pessimistic Version Constraint
      # ~1.2.3 = >=1.2.3 <1.3.0
      ver = version.gsub("\>", "")
      ver = ver.gsub("~", "")
      ver = ver.gsub(" ", "")
      highest_version = VersionService.version_tilde_newest(product.versions, ver)
      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = ver
      end
      dependency.comperator = "~"
      dependency.version_label = ver

    elsif version.match(/\A\^/)
      # Compatible with operator
      dependency.comperator = "^"
      dependency.version_label = version

      ver = version.gsub("\>", "")
      ver = ver.gsub("^", "")
      ver = ver.gsub(" ", "")

      semver = SemVer.parse( ver )
      if semver.nil?
        dependency.version_requested = ver
      else
        start = ver
        major = semver.major + 1
        upper_range = "#{major}.0.0"
        version_range   = VersionService.version_range(product.versions, start, upper_range )
        highest_version = VersionService.newest_version_from( version_range )
        if highest_version
          dependency.version_requested = highest_version.to_s
        else
          dependency.version_requested = ver
        end
      end

    elsif version.match(/\.x\z/i) || version.match(/\.\*\z/i)
      # X Version Ranges or .* version range
      ver = version[0..version.length - 2]
      versions = VersionService.versions_start_with( product.versions, ver )
      versions << version[0..version.length - 3]
      highest_version = VersionService.newest_version_from(versions)
      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = version
      end
      dependency.comperator = "="
      dependency.version_label = version

    elsif version.match(/ - /i)
      # Version Ranges
      version_splitted = version.split(" - ")
      start = version_splitted[0]
      stop = version_splitted[1]
      version_range   = VersionService.version_range(product.versions, start, stop)
      highest_version = VersionService.newest_version_from( version_range )
      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = version
      end
      dependency.comperator    = "="
      dependency.version_label = version

    else
      dependency.version_requested = version
      dependency.comperator        = "="
      dependency.version_label     = version
    end
  end

  
  def init_project( data )
    project = Project.new
    project.project_type = Project::A_TYPE_NPM
    project.language     = Product::A_LANGUAGE_NODEJS
    project.name         = data['name']
    project.description  = data['description']
    project
  end


  def init_dependency( product, name )
    dependency          = Projectdependency.new
    dependency.name     = name
    dependency.language = Product::A_LANGUAGE_NODEJS
    if product
      dependency.language        = product.language
      dependency.prod_key        = product.prod_key
      dependency.version_current = product.version
    end
    dependency
  end

  
  def pre_process version
    if version.match(/\A\d*\z/) || version.match(/\A\d*\.\d*\z/)
      version = "#{version}.*"
    end
    version
  end


end
