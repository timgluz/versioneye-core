# parser for package-lock files
# doc:
# https://docs.npmjs.com/files/package-lock.json
#

class PackageLockParser < ShrinkwrapParser
  A_MAX_DEPTH = 32

  def parse_content(content, token = nil)
    content = content.to_s.strip
    return nil if content.empty?
    return nil if (content =~ /Not\s+found/i)

    proj_doc = from_json content
    return nil if proj_doc.nil?

    project = init_project({
      'name'        => proj_doc[:name],
      'version'     => proj_doc[:version],
      'description' => "package-lock.json"
    })

    parse_dependency_items proj_doc, project
    project
  end


end
