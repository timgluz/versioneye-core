require 'versioneye/parsers/common_parser'

#parser for Elixir Mixfiles
# docs:
# https://hexdocs.pm/elixir/Version.html
#

class MixParser < CommonParser

  def parse( url )
    return nil if url.nil? || url.empty?

    content = fetch_response_body( url )
    return nil if content.nil?

    parse_content( content )
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  def parse_content(content, token = nil)
    return nil if content.to_s.empty?
    return nil if content.to_s.strip.eql?('Not Found')

    proj = init_project
    parse_dependencies project, content

    proj
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end

  def parse_dependencies(project, content)

    dep_items = extract_dep_items extract_deps_bloc preprocess(content)
    if dep_items.nil?
      log.error "parse_dependencies: found no dep items from `#{content}`"
      return
    end

    dep_items.to_a.each do |dep_line|
      parse_line(project, dep_line)
    end
  end

  def parse_line(project, dep_line)
    dep_doc  = parse_dep_item dep_line
    product = Product.where(
      language: Product::A_LANGUAGE_ELIXIR,
      prod_key: dep_doc[:name]
    ).first

    dep =  init_dependency(product, dep_doc)
    parse_requested_version( dep_doc[:version], dependency, product )

    project.projectdependencies.push dep
    project.out_number     += 1 if ProjectdependencyService.outdated?( dependency )
    project.unknown_number += 1 if product.nil?
  end

  def parse_requested_version(version_label, dependency, product)
    dependency[:version_label] = version_label #updates it for case it wasnt set

    if product.nil?
      dependency[:version_requested] = version_label
      return dependency
    end

    if version_label.nil? or version_label.empty?
      update_requested_with_current(dependency, product)
      return dependency
    end

    #TODO: handle combined version ranges

    n = version_label.size - 1
    case version_label
    when /\A==/
      version = version_label[2..n].strip
      dependency[:version_requested] = version
      dependency[:comperator] = '='

    when /\A>=/
      version = version_label[2..n].strip
      latest_version = VersionService.greater_than_or_equal(product.versions, version)
      dependency[:version_requested] = latest_version.to_s
      dependency[:comperator]        = '>='

    when /\A>/
      version = version_label[1..n].strip
      latest_version = VersionService.greater_than(product.versions, version)
      dependency[:version_requested] = latest_version.to_s
      dependency[:comperator]        = '>'

    when /\A<=/
      version = version_label[2..n].strip
      latest_version = VersionService.smaller_than_or_equal(product.versions, version)
      dependency[:version_requested] = latest_version.to_s
      dependency[:comperator]        = '<='

    when /\A</
      version = version_label[1..n].strip
      latest_version = VersionService.smaller_than(product.versions, version)
      dependency[:version_requested] = latest_version.to_s
      dependency[:comperator]        = '<'

    when /\A~>/
      version = version_label[2..n].strip
      #TODO: finish


    when /\Agit:/i
      dependency[:version_requested] = 'GIT'
      dependency[:version_label]     = 'GIT'
      dependency[:comperator]        = '='

    when /\Agithub:/i
      dependency[:version_requested] = 'GITHUB'
      dependency[:version_label]     = 'GITHUB'
      dependency[:comperator]        = '='

    when /\Apath:/i
      dependency[:version_requested] = 'PATH'
      dependency[:version_label]     = 'PATH'
      dependency[:comperator]        = '='

    end

    dependency
  end

  #parses string of Mix dependency item into Ruby hashmap
  def parse_dep_item(dep_txt)
    dep_txt = dep_txt.to_s.delete('{}') # remove brackets
    dep_txt = dep_txt.to_s.delete('\"')  #remove extra apostrophes
    dep_txt = dep_txt.to_s.strip

    dep_doc = {
      :name => nil,
      :version => nil,
      :scope => nil,
      :tag => nil
    }

    pos = 0
    dep_txt.split(',').to_a.each do |item|
      pos += 1
      item = item.to_s.strip

      # first item is always product name
      if pos == 1
        dep_doc[:name] = item.delete(':')
        next
      end

      case item
      when /\Aonly:/
        dep_doc[:scope] = parse_dep_scopes(item)

      when /\Agit:/
        dep_doc[:version] = item.to_s.gsub(/\s+/, '').strip

      when /\Atag:/
        dep_doc[:tag] = item.gsub(/\Atag:/, '').to_s.strip

      when /^[~|>|<|=|\d]/
        dep_doc[:version] = item
      end
    end

    dep_doc
  end

  #translates scope value into contants of ProjectDependency
  def parse_dep_scopes(scope_txt)
    n = scope_txt.size - 1
    return "" if n < 4

    scope_txt[4..n].to_s.delete('[]:').gsub(/\s+/, '').to_s
  end

  # takes out of dependency items from extracted dep_block
  def extract_dep_items(dep_block)
    dep_block.scan(/\{\s*[\w|:|-].+?\}/).to_a
  end

  # get only content of defp deps do ... end block
  def extract_deps_block(content)
    deps_block = ""
    tokens = content.split(/\s/)

    prev_token = tokens[0]
    start_deps = false
    tokens.to_a.each do |token|

        if prev_token == 'defp' and token == "deps"
          start_deps = true
          next
        end

        prev_token = token
        #ignore whatever tokens before beginning of deps block
        next if start_deps == false
        #ignore `do` token after block started
        next if start_deps == true and token == 'do'

        if start_deps == true and token == 'end'
          start_deps = false
          next
        end

        deps_block += ' ' + token
    end

    deps_block.to_s.strip
  end

  # remove comments, newlines and extra whitespaces
  def preprocess(content)
    content = content.to_s.gsub(/#+.*\n/, '')
    content = content.to_s.gsub(/\n|\r/, '')
    content = content.to_s.gsub(/\s+/, ' ')

    content.to_s.strip
  end

  def init_project(url = nil)
    Project.new(
      project_type: Project::A_TYPE_MIX,
      language:  Product::A_LANGUAGE_ELIXIR,
      url: url
    )
  end

  def init_dependency(product, dep_doc)
    dep = ProjectDependency.new(
      language: Product::A_LANGUAGE_ELIXIR,
      name: dep_doc[:name],
      version_label: dep_doc[:version],
      scope: dep[:scope]
    )

    if product
      dep[:prod_key] = product[:prod_key]
      dep[:version_current] = product.versio
    end

    dep
  end
end
