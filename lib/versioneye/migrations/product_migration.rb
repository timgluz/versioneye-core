class ProductMigration < Versioneye::Service

  require 'builder'

  def self.migrate
    count = 0
    Product.where(:language => 'Java', :created_at.lt => '2012-07-30').each do |product|
      next if product.versions.empty?
      group_id = product.group_id.gsub(".", "/")
      product.versions.each do |version|
        next if version.to_s.empty?

        product.version = version.to_s
        archives = product.archives
        next if archives.nil? || archives.empty?

        archives.each do |archive|
          begin
            next if version.to_s.empty?

            if archive.link.to_s.empty?
              archive.remove
            end

            if archive.link.match(/#{version.to_s}/i).nil?
              p archive
              p "- "

              product.dependencies.each do |dep|
                dep.delete
              end
              product.http_version_links.each do |link|
                link.delete
              end

              product.remove_version version.to_s
              archive.delete

              count += 1
              p count
            end
          rescue => e
            p "link: #{archive.link} - #{version.to_s}"
            p e.message
            p e.backtrace.join("\n")
          end
        end
      end
    end
  end


  def self.xml_site_map
    logger.info "xml_site_map"
    uris = Hash.new
    sitemap_count = 1

    ProductService.all_products_paged do |products|
      products.each do |product|
        next if product.nil?

        uri = "#{product.language_esc}/#{product.to_param}/#{product.version_to_url_param}"
        modified = DateTime.now.strftime("%Y-%m-%d")
        p "#{modified} - #{uri}"
        uris[uri] = {:uri => uri, :modified => modified}
      end
      if uris.count > 49000
        logger.info "#{uris.count}"
        logger.info "sitemap count: #{sitemap_count}"
        write_to_xml(uris, "sitemap-#{sitemap_count}.xml")
        uris = Hash.new
        sitemap_count += 1
      end
    end

    logger.info "#{uris.count}"
    logger.info "sitemap count: #{sitemap_count}"
    write_to_xml(uris, "sitemap-#{sitemap_count}.xml")
    return true
  rescue => e
    p e.message
    p e.backtrace.join('\n')
  end

  def self.write_to_xml(uris, name)
    logger.info "write to xml"
    xml = Builder::XmlMarkup.new( :indent => 2 )
    xml.instruct!(:xml, :encoding => "UTF8", :version => "1.0")
    xml.urlset(:xmlns => "http://www.sitemaps.org/schemas/sitemap/0.9") do |urlset|
      uris.each_pair do |key, val|
        urlset.url do |url|
          uri = val[:uri]
          modified = val[:modified]
          url.loc "https://www.versioneye.com/#{uri}"
          url.lastmod modified
        end
      end
    end
    xml_data = xml.target!
    xml_file = File.open(name, "w")
    xml_file.write(xml_data)
    xml_file.close
  end

end
