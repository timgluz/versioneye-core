class ProjectParseService < Versioneye::Service


  def self.project_from file
    project_name = file['datafile'].original_filename
    content      = file['datafile'].read

    parser  = parser_for project_name
    parse_content parser, content, project_name
  end


  def self.parser_for file_name
    type   = ProjectService.type_by_filename file_name
    parser = ParserStrategy.parser_for type, file_name
  end


  def self.parse_content parser, content, file_name, token = nil
    return nil if parser.nil? || content.to_s.empty?

    if parser.respond_to? "parse_content"
      return parser.parse_content content, token
    end

    file_path = write_to_file file_name, content
    parser.parse_file file_path
  end


  def self.write_to_file file_name, content
    rnd = SecureRandom.urlsafe_base64(7)
    file_path = "/tmp/#{rnd}_#{file_name}"
    File.open(file_path, 'w') { |file| file.write( content ) }
    file_path
  end


end
