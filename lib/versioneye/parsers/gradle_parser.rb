require 'versioneye/parsers/common_parser'

class GradleParser < CommonParser

  # Matches definitions like this;
  # project.ext.springVersion = '4.0.7.RELEASE'
  A_GLOBAL_VARS_MATCHER = /^\s*(\S*ext.\S*\s*\=\s*.*)/xi

  # Matches definitions like this;
  # def tomcatVersion = '7.0.54'
  A_GLOBAL_VARS_MATCHER_2 = /^\s*(def\s+\S+\s*=\s*["']\S*["']$)/xi

  # Matches this 'junit:junit-dep:4.0.0'
  A_DEP_SIMPLE_MATCHER = /["|']\s*([\w\.\-]+:[\w\.\-]+:[\w\.\-]+)\s*["|']/xi


  # (\w+) [\s|\(]?[\'|\"]+  ([\w|\d|\.|\-|\_]+)  :([\w|\d|\.|\-|_]+)  :([$\w|\d|\.|\-|_]+)
  A_DEP_SHORT_MATCHER = /
      (\w+) #scope
      [\s|\(]?[\'|\"]+ #scope separator
        ([\w|\d|\.|\-|\_]+) #group_id
        :([\w|\d|\.|\-|_]+) #artifact
        :([$\w|\d|\.|\-|_]+) #version number
    /xi

  # ^[\s]* (\w+) [\s]* (\w+\:) [\s]*[\'|\"]+ ([\w|\d|\.|\-|\_]+) [\'|\"]+,[\s]* (\w+\:) [\s]*[\'|\"]+ ([\w|\d|\.|\-|\_]+) [\'|\"]+,[\s]* (\w+\:) [\s]*[\'|\"]+ ([\w|\d|\.|\-|\_]+)
  A_DEP_LONG_MATCHER = /
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

  # (\[\w+\:)   [\s]*[\'|\"]+   ([\w|\d|\.|\-|\_]+)  [\'|\"]+,[\s]*  (\w+\:)  [\s]*[\'|\"]+   ([\w|\d|\.|\-|\_]+)  [\'|\"]+,[\s]*   (\w+\:)   [\s]*[\'|\"]*   ([\w|\d|\.|\-|\_]+)
  A_DEP_BR_MATCHER = /
      (\[\w+\:)             #separator
        [\s]*[\'|\"]+       #group
        ([\w|\d|\.|\-|\_]+) #group_id
        [\'|\"]+,[\s]*      #separator
        (\w+\:)             #name
        [\s]*[\'|\"]+       #separator
        ([\w|\d|\.|\-|\_]+) #artifact_id
        [\'|\"]+,[\s]*      #separator
        (\w+\:)             #version
        [\s]*[\'|\"]*       #separator
        ([\w|\d|\.|\-|\_]+) #version_id
    /xi


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

    content = content.gsub(/\/\/.*$/, "") # remove comments
    content = content.gsub(/.*classpath.*$/, "")

    vars = extract_vars content

    matches_simple = content.scan( A_DEP_SIMPLE_MATCHER )
    deps_simple = self.build_dependencies_simple(matches_simple, vars)
    content = content.gsub(A_DEP_SIMPLE_MATCHER, "")

    matches_short = content.scan( A_DEP_SHORT_MATCHER )
    deps_short    = self.build_dependencies(matches_short, vars)
    content = content.gsub(A_DEP_SHORT_MATCHER, "")

    matches_long = content.scan( A_DEP_LONG_MATCHER )
    deps_long    = self.build_dependencies_extd(matches_long, vars)
    content = content.gsub(A_DEP_LONG_MATCHER, "")

    matches_br = content.scan( A_DEP_BR_MATCHER )
    deps_br    = self.build_dependencies_br( matches_br, vars )
    content = content.gsub(A_DEP_BR_MATCHER, "")

    if deps_short[:projectdependencies] && !deps_short[:projectdependencies].empty?
      deps_short[:projectdependencies].each do |dep|
        deps_long[:projectdependencies] << dep
      end
    end
    if deps_br[:projectdependencies] && !deps_br[:projectdependencies].empty?
      deps_br[:projectdependencies].each do |dep|
        deps_long[:projectdependencies] << dep
      end
    end
    if deps_simple[:projectdependencies] && !deps_simple[:projectdependencies].empty?
      deps_simple[:projectdependencies].each do |dep|
        deps_long[:projectdependencies] << dep
      end
    end

    project              = Project.new deps_long
    project.project_type = Project::A_TYPE_GRADLE
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


  def extract_vars content
    vars = {}
    matches = content.scan(A_GLOBAL_VARS_MATCHER)
    if matches && !matches.empty?
      matches.each do |match|
        mat = match.first
        mat.gsub!("project.ext.", "")
        mat.gsub!("ext.", "")
        mat.gsub!(" ", "")
        sps = mat.split("=")
        var_key = sps[0]
        var_val = sps[1].gsub("\"", "").gsub("'", "")
        vars[var_key] = var_val
      end
    end

    matches = content.scan(A_GLOBAL_VARS_MATCHER_2)
    if matches && !matches.empty?
      matches.each do |match|
        mat = match.first
        mat.gsub!("def", "")
        sps = mat.split("=")
        var_key = sps[0].gsub(" ", "")
        var_val = sps[1].gsub(" ", "")
        var_val = var_val.gsub("\"", "").gsub("'", "")
        vars[var_key] = var_val
      end
    end
    vars
  end


  def build_dependencies( matches, vars )
    # build and initiliaze array of dependencies.
    # Arguments array of matches, should be [[scope, group_id, artifact_id, version],...]
    # Returns map {:unknowns => 0 , dependencies => []}
    data = []
    matches.each do |row|
      version = calc_version( row[4], vars )
      dependency = Projectdependency.new({
        :scope => row[1],
        :group_id => row[2],
        :artifact_id => row[3],
        :name => row[3],
        :language => Product::A_LANGUAGE_JAVA,
        :comperator => '='
      })

      process_dep version, dependency, data
    end

    {:projectdependencies => data}
  end


  def build_dependencies_simple( matches, vars )
    # build and initiliaze array of dependencies.
    # Arguments array of matches, should be [[scope, group_id, artifact_id, version],...]
    # Returns map {:unknowns => 0 , dependencies => []}
    data = []
    matches.each do |row|
      spliti = row.first.gsub("'", "").split(":")
      version = calc_version( spliti[2], vars )
      dependency = Projectdependency.new({
        :scope => 'compile',
        :group_id => spliti[0],
        :artifact_id => spliti[1],
        :name => spliti[1],
        :language => Product::A_LANGUAGE_JAVA,
        :comperator => '='
      })

      process_dep version, dependency, data
    end

    {:projectdependencies => data}
  end


  def build_dependencies_extd( matches, vars )
    data = []
    matches.each do |row|
      version = calc_version( row[6], vars )
      dependency = Projectdependency.new({
        :scope => row[0],
        :group_id => row[2],
        :artifact_id => row[4],
        :name => row[4],
        :language => Product::A_LANGUAGE_JAVA,
        :comperator => '='
      })

      process_dep version, dependency, data
    end

    {:projectdependencies => data}
  end


  def build_dependencies_br( matches, vars )
    data = []
    matches.each do |row|
      version = calc_version( row[5], vars )
      dependency = Projectdependency.new({
        :scope => nil,
        :group_id => row[1],
        :artifact_id => row[3],
        :name => row[3],
        :language => Product::A_LANGUAGE_JAVA,
        :comperator => '='
      })

      process_dep version, dependency, data
    end

    {:projectdependencies => data}
  end


  def calc_version( version_string, vars )
    return version_string if vars.nil? || vars.empty? || version_string.to_s.empty?

    version_string = version_string.gsub("$", "")
    version_string = version_string.gsub("{", "")
    version_string = version_string.gsub("}", "")
    version_string = version_string.gsub("\"", "")
    version_string = version_string.gsub(" ", "")
    if vars.keys.include?( version_string )
      version_string = vars[version_string]
    end
    version_string
  end


  def process_dep version, dependency, data
    product = Product.find_by_group_and_artifact(dependency.group_id, dependency.artifact_id)

    dependency.prod_key = product.prod_key if product
    parse_requested_version( version, dependency, product )

    dependency.stability = VersionTagRecognizer.stability_tag_for version
    VersionTagRecognizer.remove_minimum_stability version

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
      dependency.version_label = version
      dependency.comperator = "="

    end
  end


end

