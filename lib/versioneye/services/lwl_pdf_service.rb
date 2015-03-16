class LwlPdfService < Versioneye::Service 

  require 'pdfkit'

  
  def self.process project, write_to_disk = false
    fill_dto project 
    html = compile_html project
    kit  = new_kit html
    
    write_pdf_to_disk(kit, project) if write_to_disk

    kit.to_pdf
  end


  def self.compile_html project
    content_file = Settings.instance.lwl_pdf_content
    erb = ERB.new(File.read(content_file))
    html = erb.result(project.get_binding)
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


  def self.fill_dto project 
    dto = { :whitelisted => [], :unknown => [], :violated => [] }
    project.dependencies.each do |dep|
      if dep.license_caches && !dep.license_caches.empty?
        dep.license_caches.each do |lc|
          line = build_line(dep, lc.name) 
          dto[:whitelisted] << line if lc.on_whitelist
          dto[:violated]    << line if !lc.on_whitelist
        end
      else 
        dto[:unknown] << build_line(dep, 'UNKNOWN') 
      end
    end
    dto[:whitelisted].sort_by!{ |hsh| hsh[:component] }
    dto[:unknown].sort_by!{ |hsh| hsh[:component] }
    dto[:violated].sort_by!{ |hsh| hsh[:component] }
    project.lwl_pdf_list = dto
  end


  private 


    def self.build_line dep, name 
      dep_name = dep.name 
      dep_name = dep.artifact_id if !dep.artifact_id.to_s.empty?
      {:component => dep_name, :group_id => dep.group_id, :version => dep.version_requested, :license => name}
    end


end