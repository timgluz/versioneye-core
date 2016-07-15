require 'versioneye/parsers/common_parser'
require 'semverly'

class PaketParser < CommonParser
  attr_reader :comperators

  def initialize
    @comperators = Set.new(['~>', '==', '<=', '>=', '=', '<', '>'])
  end

  def semver?(version_label)
    return false if version_label.nil?
    res = SemVer.parse(version_label)

    return (res ? true : false)
  rescue
    log.error "semver?: failed to parse version #{version_label}"
    return false
  end

  def comperator?(comperator)
    false if comperator.nil?
    comperators.include?(comperator)
  end

  def parse(url)
    if url.to_s.empty?
      logger.error "PaketParser: url was empty"
      return nil
    end

    body = self.fetch.response_body(url)
    project = init_project(url)
    deps = parse_content(body)
    save_project_dependencies(project, deps)

    project
  end

  def init_project(url)
    Project.new({
      project_type: Project::A_TYPE_NUGET,
      language: Product::A_LANGUAGE_CSHARP,
      name: "Paket Project",
      url: url
    })
  end

  def parse_content(paket_doc)
    lines = paket_doc.split(/\n+/)
    if lines.empty?
      log.error "PaketParser: got empty file"
      return
    end

    deps = []
    current_group = '*'
    lines.each do |line| 
      new_group, parsed_dep = parse_line(current_group, line)
      current_group = new_group if current_group != new_group
    
      deps << parsed_dep if parsed_dep
    end

    deps
  end

  #extracts package-id, version and group/profile from the file
  def parse_line(current_group, line)
    tkns =  line.to_s.split( /\s+/ )
    return [current_group, group_doc] if tkns.empty?

    if tkns.count == 1 and tkns.first == '' and current_group != '*'
      return ['*', nil] #switch back to default group
    end

    tkns.shift if tkns.first == '' #remove empty string that caused by tabulation in groups
    
    source_id, pkg_id, comperator, version = tkns
    source_id.downcase!
    dep_dt = {
      group: current_group,
      source: source_id.downcase,
      prod_key: pkg_id,
      comperator: '*',
      version: '',
    }

    case source_id
    when 'group'
      new_group = pkg_id
      return [new_group, nil] #alert that change of group

    when 'nuget'
      if comperator?(comperator) and semver?(version)
        dep_dt[:comperator] = comperator
        dep_dt[:version] = version
      elsif semver?(comperator)
        dep_dt[:comperator] = '='
        dep_dt[:version] = comperator
      end
      
      return [current_group, dep_dt]
    
    when 'git'
      if comperator?(comperator) and version
        dep_dt[:comperator] = comperator
        dep_dt[:version] = version
      elsif comperator.to_s.size > 0
        dep_dt[:comperator] = '='
        dep_dt[:version] = comperator
      end
       
      return [current_group, dep_dt]
    when 'github'
      pkg_id, version = pkg_id.split(':')
      if version
        dep_dt[:prod_key]   = pkg_id
        dep_dt[:comperator] = '='
        dep_dt[:version]    = version
      end

      return [current_group, dep_dt]
    when 'gist'
      return [current_group, dep_dt]
    when 'http'
      return [current_group, dep_dt]
    else
      return [current_group, nil]
    end
  end

  def save_project_dependencies(project, deps)
    deps.to_a.each {|dep| save_dependency(project, dep) }
    project
  end

  def save_dependency(project, dep)
    product = Product.find_by(
      language: Product::A_LANGUAGE_CSHARP,
      prod_key: dep[:prod_key]
    )

    version_label = dep[:version]
    if version_label.to_s.empty? and product
      dep[:version] = product.version
    end
  
    dep_db = init_dependency(dep) #TODO: should i moved to parse_line?
    parse_requested_version(version_label, dep_db, product)
    
    project.out_number += 1 if dep_db.outdated?
    project.unknown_number += 1 if product.nil?
    project.projectdependencies << dep_db

    project
  end

  def init_dependency(dep)
    dep_scope = case dep[:group]
                when '*'
                  Dependency::A_SCOPE_COMPILE
                when /test/i
                  Dependency::A_SCOPE_TEST
                when /development/i
                  Dependency::A_SCOPE_DEVELOPMENT
                when /dev/i
                  Dependency::A_SCOPE_DEVELOPMENT
                else
                  nil
                end

    dep_db = Projectdependency.new(
      language: Product::A_LANGUAGE_CSHARP,
      name: dep[:prod_key],
      prod_key: dep[:prod_key],
      scope: dep_scope,
      version_label: dep[:version].to_s,
      version_requested: dep[:version].to_s,
      comperator: dep[:comperator]
      #target: dep[:target], #TODO: fetch it from line or behind version
      #source: dep[:source]  #TODO: marks where packet is hosted: nuget/github/gist/http
    )

    dep_db
  end

  def ignore_source?(dep_source)
    ['git', 'gist', 'http'].include? dep_source.to_s.downcase
  end

  def parse_requested_version(version_label, dependency, product)
    return dependency if product.nil?
    return dependency if ignore_source?(dependency[:source]) #TODO: HOW TO HANDLE WITH GIT/GIST

    if version_label.to_s.empty? 
      return self.update_requested_with_current(dependency, product)
    end

    case dependency[:comperator]
    when '*'
      self.update_requested_with_current(dependency, product)
    when '=', '=='
      dependency[:comperator] = '=' #unify comperators to '='
      return dependency
    when '>'
      newest_version = VersionService.greater_than(product.versions, version_label)
      dependency.version_requested = newest_version.to_s
    when '>='
      newest_version = VersionService.greater_than_or_equal(product.versions, version_label)
      dependency.version_requested = newest_version.to_s
    when '<'
      newest_version = VersionService.smaller_than(product.versions, version_label)
      dependency.version_requested = newest_version.to_s
    when '<='
      newest_version = VersionService.smaller_than_or_equal(product.versions, version_label)
      dependency.version_requested = newest_version.to_s
    when '~>'
      starter         = VersionService.version_approximately_greater_than_starter(version_label)
      versions        = VersionService.versions_start_with(product.versions, starter)
      highest_version = VersionService.newest_version_from(versions)
      if highest_version
        dependency.version_requested = highest_version.to_s
      end
    end

    #TODO: how to handle http, git, gist
    
    dependency
  end
end
