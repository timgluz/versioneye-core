class CommonUpdater < Versioneye::Service


  def update_old_with_new old_project, new_project, send_email = false
    old_project.update_from new_project
    old_project.reload
    cache.delete( old_project.id.to_s ) # Delete badge status for project
    if send_email && old_project.out_number > 0 && old_project.user.email_inactive == false
      log.info "Send out email notification for project #{old_project.name} to user #{old_project.user.fullname}"
      ProjectMailer.projectnotification_email( old_project ).deliver
    end
  end


  def write_to_file file_name, content
    rnd = SecureRandom.urlsafe_base64(7)
    file_path = "/tmp/#{rnd}_#{file_name}"
    File.open(file_path, 'w') { |file| file.write( content ) }
    file_path
  end


  def parser_for file_name
    type   = ProjectService.type_by_filename file_name
    parser = ParserStrategy.parser_for type, file_name
  end


  def parse_content parser, content, file_name
    return nil if parser.nil? || content.to_s.empty?

    if parser.respond_to? "parse_content"
      return parser.parse_content content
    end

    file_path = write_to_file file_name, content
    parser.parse_file file_path
  end


  private

    def log
      CommonUpdater.log
    end

    def cache
      CommonUpdater.cache
    end

end
