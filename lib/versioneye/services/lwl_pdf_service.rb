class LwlPdfService < Versioneye::Service 

  require 'pdfkit'

  
  def self.process project 
    fill_dto project 
    html = compile_html project
    pdf  = compile_pdf html, project 
  end


  def self.compile_html project
    # content_file = Settings.instance.receipt_content
    content_file = 'lib/versioneye/views/lwl_pdf/lwl_pdf.html.erb'

    erb = ERB.new(File.read(content_file))
    html = erb.result(project.get_binding)
    html = html.force_encoding(Encoding::UTF_8)

    html
  end


  # Note for me.. kit.to_file('/Users/robertreiz/invoice.pdf')
  def self.compile_pdf html, project = nil
    # footer_file = Settings.instance.receipt_footer
    footer_file = 'lib/versioneye/views/lwl_pdf/footer.html'
    kit = PDFKit.new(html, :footer_html => footer_file, :page_size => 'A4')

    raise "PDFKit.new returned nil!" if kit.nil?

    if project 
      project_name = project.name.gsub("/", "-")
      kit.to_file("#{ENV['HOME']}/#{project_name}.pdf")
    end

    kit.to_pdf
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
      {:component => dep.name, :version => dep.version_requested, :license => name}
    end


end