require 'versioneye/parsers/nuget_parser'

class CsprojParser < NugetParser

  #read all dependency data from project file
  def parse_dependencies(doc)
    deps = []
    doc.xpath('//Project/ItemGroup/PackageReference').each do |pkg_node|
      dep = parse_dependency(pkg_node)
      deps << dep if dep.nil? == false
    end

    deps
  end

  def parse_dependency(pkg_node)
    prod_key = pkg_node.attr('Include').to_s.strip
    version_label = if pkg_node.has_attribute?('Version')
                      pkg_node.attr('Version').to_s.strip
                    else
                      #version wasnt specified as attribute, check child nodes
                      pkg_node.xpath('//Version').text
                    end

    init_dependency(prod_key, version_label, nil, Dependency::A_SCOPE_COMPILE)
  end

end
