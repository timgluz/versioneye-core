require 'versioneye/parsers/common_parser'

class GradleParser < CommonParser


  def parse(url)
    return nil if url.nil?

    content = self.fetch_response(url).body
    parse_content( content )
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def parse_content( content )
    return nil if content.nil?

    dep_matcher_short = /
      ^(\s)* #filter out comments
      (\w+) #scope
      [\s|\(]?[\'|\"]+ #scope separator
        ([\w|\d|\.|\-|\_]+) #group_id
        :([\w|\d|\.|\-|_]+) #artifact
        :([\w|\d|\.|\-|_]+) #version number
    /xi

    dep_matcher_long = /
      ^[\s]*              #filter out comments
      (\w+)               #scope
      [\s]*               #scope separator
      (\w+\:)             #group
      [\s]*[\'|\"]+       #separator
      ([\w|\d|\.|\-|\_]+) #group_id
      [\'|\"]+,[\s]*      #separator
      (\w+\:)             #name
      [\s]*[\'|\"]+       #separator
      ([\w|\d|\.|\-|\_]+) #artifact_id
      [\'|\"]+,[\s]*      #separator
      (\w+\:)             #version
      [\s]*[\'|\"]+       #separator
      ([\w|\d|\.|\-|\_]+) #version_id
    /xi

    # ^[\s]* (\w+) [\s]* (\w+\:) [\s]*[\'|\"]+ ([\w|\d|\.|\-|\_]+) [\'|\"]+,[\s]* (\w+\:) [\s]*[\'|\"]+ ([\w|\d|\.|\-|\_]+) [\'|\"]+,[\s]* (\w+\:) [\s]*[\'|\"]+ ([\w|\d|\.|\-|\_]+)

    matches_short = content.scan( dep_matcher_short )
    deps_short    = self.build_dependencies(matches_short)

    matches_long = content.scan( dep_matcher_long )
    deps_long    = self.build_dependencies_extd(matches_long)

    deps_long[:unknown_number] += deps_short[:unknown_number]
    deps_long[:out_number]     += deps_short[:out_number]
    if deps_short[:projectdependencies] && !deps_short[:projectdependencies].empty?
      deps_short[:projectdependencies].each do |dep|
        deps_long[:projectdependencies] << dep
      end
    end

    project              = Project.new deps_long
    project.project_type = Project::A_TYPE_GRADLE
    project.language     = Product::A_LANGUAGE_JAVA
    project.dep_number   = project.dependencies.size
    project
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def build_dependencies( matches )
    # build and initiliaze array of dependencies.
    # Arguments array of matches, should be [[scope, group_id, artifact_id, version],...]
    # Returns map {:unknowns => 0 , dependencies => []}
    data = []
    unknowns, out_number = 0, 0
    matches.each do |row|
      version = row[4]
      dependency = Projectdependency.new({
        :scope => row[1],
        :group_id => row[2],
        :artifact_id => row[3],
        :name => row[3],
        :language => Product::A_LANGUAGE_JAVA,
        :comperator => '='
      })

      process_dep version, dependency, unknowns, out_number, data
    end

    {:unknown_number => unknowns, :out_number => out_number, :projectdependencies => data}
  end


  def build_dependencies_extd( matches )
    data = []
    unknowns, out_number = 0, 0
    matches.each do |row|
      version = row[6]
      dependency = Projectdependency.new({
        :scope => row[0],
        :group_id => row[2],
        :artifact_id => row[4],
        :name => row[4],
        :language => Product::A_LANGUAGE_JAVA,
        :comperator => '='
      })

      process_dep version, dependency, unknowns, out_number, data
    end

    {:unknown_number => unknowns, :out_number => out_number, :projectdependencies => data}
  end


  def process_dep version, dependency, unknowns, out_number, data
    product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id)
    if product
      dependency.prod_key = product.prod_key
    else
      unknowns += 1
    end

    parse_requested_version( version, dependency, product )

    dependency.stability = VersionTagRecognizer.stability_tag_for version
    VersionTagRecognizer.remove_minimum_stability version

    out_number += 1 if ProjectdependencyService.outdated?( dependency )
    data << dependency
  end


  def parse_requested_version(version, dependency, product)
    if version.nil? || version.empty?
      self.update_requested_with_current(dependency, product)
      return
    end
    version = version.to_s.strip
    version = version.gsub('"', '')
    version = version.gsub("'", '')

    if product.nil?
      dependency.version_requested = version
      dependency.version_label = version

    elsif version.match(/\.\+\z/i) or version.match(/\.\z/i)
      # Newest available static version
      # http://www.gradle.org/docs/current/userguide/dependency_management.html#sec:dependency_resolution
      ver = version.gsub('+', '')
      starter = ver.gsub(' ', '')
      versions        = VersionService.versions_start_with( product.versions, starter )
      highest_version = VersionService.newest_version_from( versions )
      if highest_version
        dependency.version_requested = highest_version.to_s
      else
        dependency.version_requested = ver
      end
      dependency.comperator = "="
      dependency.version_label = "#{ver}+"

    else
      dependency.version_requested = version
      dependency.comperator = "="
      dependency.version_label = version

    end
  end


end

