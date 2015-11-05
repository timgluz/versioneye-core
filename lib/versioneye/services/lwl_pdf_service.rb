class LwlPdfService < LwlService


  def self.process_all projects, flatten = true, write_to_disk = false
    html = compile_all_html projects, flatten
    kit  = new_kit html

    write_pdf_to_disk(kit, projects.first.user.username) if write_to_disk

    kit.to_pdf
  end


  def self.compile_all_html projects, flatten = true
    project = projects.first
    stop = projects.count - 1
    kids = projects[1..stop]

    fill_dto project, flatten
    kids.each do |project|
      fill_dto project, flatten
    end

    namespace = OpenStruct.new(project: project, children: kids)
    content_file = Settings.instance.lwl_pdf_content
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
    content_file = Settings.instance.lwl_pdf_content
    erb = ERB.new(File.read(content_file))
    html = erb.result( namespace.instance_eval { binding } )

    html = html.force_encoding(Encoding::UTF_8)
    html
  end


  def self.new_kit html
    footer_file = Settings.instance.lwl_pdf_footer
    kit = PDFKit.new(html, :footer_html => footer_file, :page_size => 'A4')

    raise "PDFKit.new returned nil!" if kit.nil?

    kit
  end


  def self.write_pdf_to_disk kit, name
    date_string = DateTime.now.strftime("%d_%m_%Y")
    project_name = name.to_s.gsub("/", "-")
    kit.to_file("#{ENV['HOME']}/#{date_string}_#{project_name}.pdf")
  end


end
