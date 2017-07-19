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

    project_doc = parse_into_ruby(rebar_txt)
    if project_doc.nil? or project_doc.empty?
      log.error "parse_content: failed to decode erlang blocks into ruby data"
      return
    end

    p project_doc
    # create project
    # parse dependencies

  rescue => e
    log.error "ERROR in parse_content:\n#{rebar_txt}"
    log.error "\treason: #{e.message}"
    log.error e.backtrace.join('\n')
    nil
  end

  def init_project( url = nil )
    Project.new(
      language: Product::A_LANGUAGE_ERLANG,
      project_type: Project::A_TYPE_HEX,
      name: "rebar3_project"
    )
  end

  def init_dependency(product, dep_name)
    dep = Projectdependency.new(
      name: dep_name,
      language: Product::A_LANGUAGE_ERLANG
    )

    if product
      dep.name      = product.name
      dep.language  = product.language
      dep.prod_key  = product.prod_key
      dep.version_current = product.version
    end


    dep
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

    txt.to_s
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
