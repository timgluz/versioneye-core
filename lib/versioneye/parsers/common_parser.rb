require 'versioneye/log'
require 'nokogiri'
require 'json'

class CommonParser

  def log
    Versioneye::Log.instance.log
  end

  def parse(url)
    raise NotImplementedError, 'Implement me in subclass!'
  end

  def from_json(json_doc)
    doc = nil
    begin
      doc = JSON.parse(json_doc, {symbolize_names: true})
    rescue
      log.error "Failed to parse #{json_doc}"
    end

    doc
  end
=begin

  One of this bothe methods needs to be implemented in each subclass.

  def parse_file(file_path)
    raise NotImplementedError, 'Implement me in subclass!'
  end

  def parse_content(content, token = nil)
    raise NotImplementedError, 'Implement me in subclass!'
  end
=end

  # It is important that this method is NOT writing into the database!
  #
  # Params:
  #   version           = the unparsed version string from the project file, e.g. '>= 2.0.1'
  #   projectdependency = This object can be empty/new. The results of the method are stored in this object
  #   product           = The corresponding product to the dependency. It can be nil if the dependency is unknown.
  #
  # Result: The method is parsing the version string and setting this values in projectdependency
  #   - projectdependency.version_label
  #   - projectdependency.version_requested
  #   - projectdependency.stability
  #   - projectdependency.comperator
  #
  def parse_requested_version(version, projectdependency, product)
    raise NotImplementedError, 'Implement me in subclass!'
  end

  def fetch_response url
    url = self.do_replacements_for_github url
    HttpService.fetch_response url
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  def fetch_response_body( url )
    response = self.fetch_response( url )
    response.body
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end

  def do_replacements_for_github(url)
    if url.match(/^https:\/\/github.com\//)
      url = url.gsub('https://github.com', 'https://raw.githubusercontent.com')
      url = url.gsub('/blob/', '/')
    end
    url
  end

  def update_requested_with_current( dependency, product )
    if product && product.version
      dependency.version_requested = VersionService.newest_version product.versions
    else
      dependency.version_requested = 'UNKNOWN'
    end
    #dependency.version_current = dependency.version_requested #TODO: should it update current version too?
    dependency
  end

  def fetch_xml( content )
    doc = Nokogiri::XML( content )
    return nil if doc.nil?

    doc.remove_namespaces!
    return nil if doc.nil?

    doc
  end

end
