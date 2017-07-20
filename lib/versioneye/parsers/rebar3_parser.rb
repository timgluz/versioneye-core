require 'erlang_config'

require 'versioneye/parsers/common_parser'

class Rebar3Parser < CommonParser
  attr_reader :auth_token


  def parse(url)
    return nil if url.nil? or url.empty?

    content = fetch_response_body(url)
    if content.nil? or content.empty?
      log.error "rebar3_parser.parse: no content from #{url}"
      return
    end

    parse_content content
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    nil
  end

  def parse_content(rebar_txt, token = nil)
    rebar_txt = preprocess_text(rebar_txt)
    return if rebar_txt.empty?

    # parse plain erlang file to ruby hashmap
    project_doc = parse_into_ruby(rebar_txt)
    if project_doc.nil? or project_doc.empty?
      log.error "parse_content: failed to decode erlang blocks into ruby data"
      return
    end

    p project_doc[:deps], project_doc[:profiles]


    # parse dependencies
    deps = parse_dependencies(project_doc[:deps]).to_a
    deps += parse_profile_dependencies(project_doc[:profiles]).to_a
    if deps.nil?
      log.error "parse_content: failed to parse dependencies"
      return
    end

    # create project and attach processed dependencies
    project = init_project
    process_project_dependencies(project, deps)

    project
  rescue => e
    log.error "ERROR in parse_content:\n#{rebar_txt}"
    log.error "\treason: #{e.message}"
    log.error e.backtrace.join('\n')
    nil
  end

  def process_project_dependencies(project, deps)
    return project if deps.nil? or deps.empty?

    deps.each {|dep_db| process_project_dependency(project, dep_db)}

    project
  end

  def process_project_dependency(project, dep_db)
    return if dep_db.nil?

    product = Product.where(
      prod_type: Project::A_TYPE_HEX,
      prod_key: dep_db[:prod_key]
    ).first

    if product
      parse_requested_version(dep_db[:version_label], dep_db, product)
      dep_db[:language] = product.language
      dep_db[:version_current] = product.version
    else
      project.unknown_number += 1
    end

    project.projectdependencies << dep_db
    project.out_number += 1 if ProjectdependencyService.outdated?(dep_db)
    project
  end

  def parse_requested_version(version_label, dep_db, product)
    version_label = version_label.to_s.strip

    case version_label
    when /\A\*/
      # select the newest
    when /\Agit\+/
     # handle github version
    when /\A\.*/
      # handle 0.x
    when /\d+\.\*/
      # handle patterns
    when /\A\d+/, /\A\d+\.\d+/
      # handle exact semver match
    else
      log.error "parse_requested_version"
    end

    dep_db
  end

  def parse_profile_dependencies(profile_doc)
    profile_doc.to_a.reduce([]) do |acc, profile_item|
      scope_name = profile_item.keys.first.to_s
      profile = profile_item.values.first.find {|x| x.keys.include?(:deps)}
      if profile
        deps = parse_dependencies(profile[:deps], scope_name).to_a
        acc += deps
      end

      acc
    end
  end

  def parse_dependencies(dep_items, scope = Dependency::A_SCOPE_COMPILE)
    dep_items.to_a.reduce([]) do |acc, dep_doc|
      dep_db = parse_dependency(dep_doc, scope)
      if dep_db
        acc << dep_db
      else
        log.error "parse_dependencies: failed to parse #{dep_doc}"
      end

      acc
    end
  end

  def parse_dependency(dep_doc, scope)

    p "#-- scope: #{scope} --> #{dep_doc}"
    prod_key = dep_doc.keys.first.to_s
    version_label = extract_version_label(dep_doc.values.first)

    p "#-- #{prod_key} --> #{version_label}"

    init_dependency(prod_key, version_label, scope)
  end

  def extract_version_label(version_doc)
    if version_doc.nil?
      "*"
    elsif version_doc.is_a?(String)
      version_doc
    elsif version_doc.is_a?(Hash)
      scm_id = version_doc.keys.first.to_s
      scm_val = version_doc.values.first
      extract_scm_label(scm_id, scm_val)

    elsif version_doc.is_a?(Array)
      #find plain version string, ignore SCM details
      lbl = version_doc.find {|x| x.is_a?(String) }
      return lbl if lbl

      #find first hash map that includes SCM info
      scm_doc = version_doc.find {|x| x.is_a?(Hash) }
      if scm_doc
        extract_scm_label( scm_doc.keys.first, scm_doc.values.first )
      end
    end
  end

  # turns SCM values into scm version label
  def extract_scm_label(scm_id, scm_doc)
    scm_id = scm_id.to_s.strip

    if scm_doc.is_a?(String)
      "#{scm_id}+#{scm_doc}"
    elsif scm_doc.is_a?(Array)
      scm_url = scm_doc.find {|x| x.is_a?(String) }
      scm_tag_doc = scm_doc.find {|x| x.is_a?(Hash)}
      scm_tag = fetch_scm_tag(scm_tag_doc)
      if scm_tag
        "#{scm_id}+#{scm_url}##{scm_tag}"
      else
        "#{scm_id}+#{scm_url}"
      end
    else
      log.error "extract_scm_label: failed to extract from #{scm_doc}"
      nil
    end
  end

  def fetch_scm_tag(tag_doc)
    return nil if tag_doc.is_a?(Hash) == false
    ( tag_doc[:tag] || tag_doc[:rev] || tag_doc[:ref] || tag_doc[:branch] )
  end

  def init_project( url = nil )
    Project.new(
      language: Product::A_LANGUAGE_ERLANG,
      project_type: Project::A_TYPE_HEX,
      name: "rebar3_project"
    )
  end

  def init_dependency(prod_key, version_label, scope = nil)
    Projectdependency.new(
      language: Product::A_LANGUAGE_ERLANG,
      prod_key: prod_key,
      name: prod_key,
      version_label: version_label,
      scope: scope
    )
  end

  def parse_into_ruby(rebar_txt)
    project_doc = {}

    split_into_blocks(rebar_txt).to_a.each do |block_txt|
      doc = parse_block(block_txt)
      project_doc.merge!(doc) if doc.is_a?(Hash)
    end

    project_doc
  rescue
    log.error "parse_into_ruby: failed to parse `#{rebar_txt}`"
    nil
  end


  def parse_block(block_txt)
    ErlangConfig.decode(block_txt.to_s)
  rescue => e
    log.error "parse_block: failed to parse `#{block_txt}`"
    log.error e.backtrace.join('\n')
    nil
  end

  # split document into separate blocks, which could be parsed with ErlangConfig
  def split_into_blocks(rebar_txt)
    blocks = []
    current_block = ""
    beginnings = []

    rebar_txt.each_char do |c|

      # keep track of beginnings and closings of the blocks
      case c
      when '{' then beginnings.push(c)
      when '}' then beginnings.pop
      end

      # if beginnigs stack is empty, then we are out of block
      if beginnings.empty?
        # ignore empty strings
        if current_block.size > 0
          blocks << current_block.strip + '}'
          current_block = ""
        end
      else
        # ignore all the stuff outside block ~ spaces, comments, dots
        current_block += c
      end

    end

    blocks
  end

  # it fixes encoding issues, removes comments and newlines
  def preprocess_text(txt)
    txt = txt.to_s.encode("UTF-8")

    txt = remove_comments(txt)
    txt = txt.to_s.gsub(/\n|\r/, ' ') # remove new lines
    txt = txt.to_s.gsub(/\s+/, ' ') # remove repeating spaces

    txt.to_s.strip
  rescue => e
    log.error "preprocess_text: failed to preprocess text #{e.message}"
    log.error e.backtrace.join('\n')
    ""
  end


  # split text into lines and remove line comments
  def remove_comments(txt)
    txt.split(/\n/).to_a.reduce("") do |acc, line|
      acc += line.to_s.gsub(/(?<!\"|\w|\%)\%.+\z/, ' ')
      acc
    end
  end
end
