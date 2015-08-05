class LwlPdfService < Versioneye::Service

  require 'pdfkit'
  require 'ostruct'


  def self.process project, exclude_kids = false, flatten = true, write_to_disk = false
    html = compile_html project, exclude_kids, flatten
    kit  = new_kit html

    write_pdf_to_disk(kit, project) if write_to_disk

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


  def self.write_pdf_to_disk kit, project
    date_string = DateTime.now.strftime("%d_%m_%Y")
    project_name = project.name.gsub("/", "-")
    kit.to_file("#{ENV['HOME']}/#{date_string}_#{project_name}.pdf")
  end


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
    dto = { :whitelisted => [], :unknown => [], :violated => [] }

    fill_dto_with project.dependencies, dto, uniq_array

    if flatten && project.children && !project.children.empty?
      project.children.each do |child|
        fill_dto_with child.dependencies, dto, uniq_array
      end
    end

    dto[:whitelisted].sort_by!{ |hsh| hsh[:component] }
    dto[:unknown].sort_by!{ |hsh| hsh[:component] }
    dto[:violated].sort_by!{ |hsh| hsh[:component] }
    project.lwl_pdf_list = dto
    dto
  end


  private


    def self.fill_dto_with dependencies, dto, uniq_array
      uvalue = ''
      dependencies.each do |dep|
        line = build_line(dep)
        if dep.license_caches && !dep.license_caches.empty?
          dep.license_caches.each do |lc|
            line[:license] = lc.name
            uvalue = create_uniq_identifier(line)
            next if uniq_array.include?(uvalue)

            dto[:whitelisted] << line if lc.on_whitelist
            dto[:violated]    << line if !lc.on_whitelist
          end
        else
          line[:license] = 'UNKNOWN'
          uvalue = create_uniq_identifier(line)
          dto[:unknown] << line if !uniq_array.include?(uvalue)
        end

        uniq_array << uvalue if !uniq_array.include?(uvalue)
      end
    end


    def self.create_uniq_identifier line
      "#{line[:component]}_#{line[:group_id]}_#{line[:version]}_#{line[:license]}"
    end


    def self.build_line dep
      dep_name = dep.name
      dep_name = dep.artifact_id if !dep.artifact_id.to_s.empty?
      {:component => dep_name, :group_id => dep.group_id, :version => dep.version_requested}
    end


end