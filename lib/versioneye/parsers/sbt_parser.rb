require 'versioneye/parsers/common_parser'

class SbtParser < CommonParser

  # matches: val akkaVersion = "2.3.11"
  A_VAL_MATCHER = /\s*val\s*(\S+)\s*=\s*\"(\S+)\"/xi

  # matches "<GROUP_ID>" %% "<ARTIFACT_ID" % CONSTANT
  A_DEP_VAL_MATCHER = /\"(\S+)\"\s*\%+\s*\"(\S+)\"\s*\%+\s*(\S+)\s*[,\n]/xi 

  # matches "<GROUP_ID>" %% "<ARTIFACT_ID" % "VERSION"
  A_DEP_MATCHER = /\"(\S+)\"\s*\%+\s*\"(\S+)\"\s*\%+\s*\"(\S+)\"/xi  

  # matches "<GROUP_ID>" %% "<ARTIFACT_ID" % CONSTANT  % "SCOPE"
  #         "<GROUP_ID>" %% "<ARTIFACT_ID" % "VERSION" % "SCOPE"
  A_DEP_SCOPE_MATCHER = /\"(\S+)\"\s*\%+\s*\"(\S+)\"\s*\%+\s*(\S+)\s*\%+\s*\"(\S+)\"/xi

  # matches 
  # A_DEP_SCOPE_MATCHER = /\"(\S+)\"\s*\%+\s*\"(\S+)\"\s*\%+\s*\"(\S+)\"\s*\%+\s*\"(\S+)\"/xi

  
  def parse( url )
    return nil if url.nil?

    content = self.fetch_response(url).body
    parse_content( content )
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def parse_content( content )
    return nil if content.to_s.empty?
    return nil if content.to_s.strip.eql?('Not Found')

    content = content.gsub(/\/\*.*?\*\//mxi, "")              # remove comments /* */ 
    content = content.gsub(/\A\/\/.*$/xi, "")                 # remove comments // 
    content = content.gsub(/[^[https:][http:]]\/\/.*$/xi, "") # remove comments // without http[s]

    vals = {}
    val_matches = content.scan( A_VAL_MATCHER )
    content     = content.gsub( A_VAL_MATCHER, "")
    vals        = parse_vals(vals, val_matches)

    scope_matches = content.scan( A_DEP_SCOPE_MATCHER )
    content       = content.gsub( A_DEP_SCOPE_MATCHER, "")
    deps_scoped   = self.build_dependencies(scope_matches, vals)

    matches    = content.scan( A_DEP_MATCHER )
    content    = content.gsub( A_DEP_MATCHER, "")
    deps_short = self.build_dependencies(matches, vals)

    matches_c    = content.scan( A_DEP_VAL_MATCHER )
    content      = content.gsub( A_DEP_VAL_MATCHER, "")
    deps_short_c = self.build_dependencies(matches_c, vals)

    deps = {}
    deps[:projectdependencies] = []
    keys = {}

    fill_deps( deps_scoped, deps, keys )
    fill_deps( deps_short, deps, keys )
    fill_deps( deps_short_c, deps, keys )

    project              = Project.new deps
    project.project_type = Project::A_TYPE_SBT
    project.language     = Product::A_LANGUAGE_JAVA
    project.dep_number   = project.dependencies.size

    project.dependencies.each do |dependency|
      project.out_number     += 1 if ProjectdependencyService.outdated?( dependency )
      project.unknown_number += 1 if dependency.product.nil?
    end

    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def fill_deps dependencies, deps, keys
    return if dependencies.nil? || dependencies[:projectdependencies].nil? || dependencies[:projectdependencies].empty?
    
    dependencies[:projectdependencies].each do |dep|
      key = "#{dep.group_id}:#{dep.artifact_id}"
      deps[:projectdependencies] << dep if keys[key].to_s.empty?
      keys[key] = dep
    end
  end


  def parse_vals( map, matches )
    matches.each do |row|
      map[row[0]] = row[1]
    end
    map 
  end


  def build_dependencies( matches, vals )
    data = []
    matches.each do |row|

      version = row[2]

      scope = row[3]
      scope = 'compile' if scope.to_s.empty?

      dependency = Projectdependency.new({
        :scope => scope,
        :group_id => row[0],
        :artifact_id => row[1],
        :name => row[1],
        :language => Product::A_LANGUAGE_JAVA,
        :comperator => '='
      })

      process_dep version, dependency, data, vals
    end

    {:projectdependencies => data}
  end


  def process_dep version, dependency, data, vals
    product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id)

    dependency.prod_key = product.prod_key if product

    parse_requested_version( version, dependency, product, vals )

    dependency.stability = VersionTagRecognizer.stability_tag_for version
    VersionTagRecognizer.remove_minimum_stability version

    data << dependency
    data
  end


  def parse_requested_version(version, dependency, product, vals)
    if version.to_s.empty?
      self.update_requested_with_current(dependency, product)
      return
    end
    version = version.to_s.strip
    version = version.gsub(/,\z/, '')
    version = version.gsub('"', '')
    version = version.gsub("'", '')
    version = vals[version] if !vals[version].to_s.empty? 

    if product.nil?
      dependency.version_requested = version
      dependency.version_label = version

    else
      dependency.version_requested = version
      dependency.comperator = "="
      dependency.version_label = version

    end
  end


end

