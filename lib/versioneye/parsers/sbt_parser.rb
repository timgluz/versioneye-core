require 'versioneye/parsers/common_parser'

class SbtParser < CommonParser

  A_DEP_MATCHER = /\"(\S+)\"\s*\%+\s*\"(\S+)\"\s*\%+\s*\"(\S+)\"/xi
  A_DEP_SCOPE_MATCHER = /\"(\S+)\"\s*\%+\s*\"(\S+)\"\s*\%+\s*\"(\S+)\"\s*\%+\s*\"(\S+)\"/xi

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

    content = content.gsub(/\/\/.*$/, "") # remove comments

    matches    = content.scan( A_DEP_MATCHER )
    deps_short = self.build_dependencies(matches)

    scope_matches = content.scan( A_DEP_SCOPE_MATCHER )
    deps_scoped   = self.build_dependencies(scope_matches)

    deps = {}
    deps[:projectdependencies] = []
    keys = {}
    if deps_scoped[:projectdependencies] && !deps_scoped[:projectdependencies].empty?
      deps_scoped[:projectdependencies].each do |dep|
        key = "#{dep.group_id}:#{dep.artifact_id}"
        deps[:projectdependencies] << dep if keys[key].to_s.empty?
        keys[key] = dep
      end
    end
    if deps_short[:projectdependencies] && !deps_short[:projectdependencies].empty?
      deps_short[:projectdependencies].each do |dep|
        key = "#{dep.group_id}:#{dep.artifact_id}"
        deps[:projectdependencies] << dep if keys[key].to_s.empty?
        keys[key] = dep
      end
    end

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


  def build_dependencies( matches )
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

      process_dep version, dependency, data
    end

    {:projectdependencies => data}
  end


  def process_dep version, dependency, data
    product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id, dependency.language)

    dependency.prod_key = product.prod_key if product

    parse_requested_version( version, dependency, product )

    dependency.stability = VersionTagRecognizer.stability_tag_for version
    VersionTagRecognizer.remove_minimum_stability version

    data << dependency
    data
  end


  def parse_requested_version(version, dependency, product)
    if version.to_s.empty?
      self.update_requested_with_current(dependency, product)
      return
    end
    version = version.to_s.strip
    version = version.gsub('"', '')
    version = version.gsub("'", '')

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

