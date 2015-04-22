require 'versioneye/parsers/common_parser'
require 'semverly'

class BiicodeParser


  # 
  #
  def parse( url )
    return nil if url.to_s.empty?

    body = self.fetch_response_body( url )
    parse_content( body )
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  def parse_content( content )
    data = JSON.parse( content )
    return nil if data.nil?

    project = init_project( data )

    # TODO implement me 

  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    nil
  end


  # It is important that this method is not writing into the database!
  def parse_requested_version(version_number, dependency, product)
    if version_number.to_s.empty?
      self.update_requested_with_current(dependency, product)
      return
    end

    if product.nil?
      dependency.version_requested = version_number
      dependency.version_label     = version_number
      return
    end

    version = String.new( version_number )

    version.gsub!('=', '')
    version.gsub!(' ', '')
    dependency.version_requested = version
    dependency.version_label     = version
    dependency.comperator        = '='

    dependency    
  end


  def init_project( data )
    project = Project.new
    project.project_type = Project::A_TYPE_BIICODE
    project.language     = Product::A_LANGUAGE_BIICODE
    project.name         = data['name']
    project.description  = data['description']
    project
  end


end
