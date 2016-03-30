class SecPdfService


  def self.process_all projects, write_to_disk = false
    html = compile_all_html projects
    kit  = new_kit html
    write_pdf_to_disk(kit, projects.first.user.username) if write_to_disk
    kit.to_pdf
  end


  def self.compile_all_html projects, flatten = true
    projects.each do |project|
      fill_dto project, flatten
    end

    namespace = OpenStruct.new(projects: projects)
    content_file = Settings.instance.sec_pdf_multi_content
    erb = ERB.new(File.read(content_file))
    html = erb.result( namespace.instance_eval { binding } )
    html = html.force_encoding(Encoding::UTF_8)
    html
  end


  def self.process project, exclude_kids = false, flatten = true, write_to_disk = false
    html = compile_html project, exclude_kids, flatten
    kit  = new_kit html
    write_pdf_to_disk(kit, project.name) if write_to_disk
    kit.to_pdf
  end


  def self.compile_html project, exclude_kids = false, flatten = true
    fill_dto project, flatten
    children = prepare_kids project, exclude_kids, flatten
    namespace = OpenStruct.new(project: project, children: children)
    content_file = Settings.instance.sec_pdf_content
    erb = ERB.new(File.read(content_file))
    html = erb.result( namespace.instance_eval { binding } )
    html = html.force_encoding(Encoding::UTF_8)
    html
  end


  def self.new_kit html
    footer_file = Settings.instance.sec_pdf_footer
    kit = PDFKit.new(html, :footer_html => footer_file, :page_size => 'A4')

    raise "PDFKit.new returned nil!" if kit.nil?

    kit
  end


  def self.write_pdf_to_disk kit, name
    date_string = DateTime.now.strftime("%d_%m_%Y")
    project_name = name.to_s.gsub("/", "-")
    kit.to_file("#{ENV['HOME']}/#{date_string}_#{project_name}_sec.pdf")
  end


  private


    def self.prepare_kids project, exclude_kids = false, flatten
      children = []
      return children if exclude_kids || flatten

      if project.children && !project.children.empty?
        project.children.each do |sub_project|
          fill_dto sub_project, false
          children << sub_project
        end
      end
      children
    end


    def self.fill_dto project, flatten = false
      uniq_array = []
      dto = { :ok => [], :vulnerable => [] }

      fill_dto_with project.dependencies, dto, uniq_array

      if flatten && project.children && !project.children.empty?
        project.children.each do |child|
          fill_dto_with child.dependencies, dto, uniq_array
        end
      end

      dto[:ok].sort_by!{ |hsh| hsh[:component] }
      dto[:vulnerable].sort_by!{ |hsh| hsh[:component] }
      project.sec_pdf_list = dto
      dto
    end


    def self.fill_dto_with dependencies, dto, uniq_array
      dependencies.each do |dep|
        if dep.sv_ids && !dep.sv_ids.empty?
          line_per_sv( dep, dto, uniq_array )
        else
          ok_line( dep, dto, uniq_array )
        end
      end
    end


    def self.ok_line dep, dto, uniq_array
      line = build_line(dep)
      line[:status] = 'OK'
      uvalue = create_uniq_identifier(line)
      if !uniq_array.include?(uvalue)
        dto[:ok] << line
        uniq_array << uvalue
      end
    end


    def self.line_per_sv dep, dto, uniq_array
      lines = []
      dep.sv_ids.each do |sv_id|
        line = build_line(dep)
        line[:status] = 'vulnerable'
        line[:sv_id] = sv_id
        lines << line
      end

      lines.each do |line|
        uvalue = create_uniq_identifier(line)
        next if uniq_array.include?(uvalue)

        uniq_array << uvalue
        dto[:vulnerable] << line
      end
    end


    def self.create_uniq_identifier line
      "#{line[:component]}_#{line[:group_id]}_#{line[:version]}_#{line[:status]}"
    end


    def self.build_line dep
      dep_name = dep.name
      dep_name = dep.artifact_id if !dep.artifact_id.to_s.empty?
      {:language => dep.language, :component => dep_name, :group_id => dep.group_id, :version => dep.version_requested}
    end


end
