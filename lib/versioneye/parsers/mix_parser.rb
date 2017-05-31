require 'versioneye/parsers/common_parser'

class MixParser < CommonParser

  def extract_deps_block(content)
    deps_block = ""
    tokens = content.split(/\s/)

    prev_token = tokens[0]
    start_deps = false
    tokens.to_a.each do |token|

        if prev_token = 'defp' and token == "deps"
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
end
