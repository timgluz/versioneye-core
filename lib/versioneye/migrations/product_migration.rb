class ProductMigration < Versioneye::Service

  require 'builder'

  def self.xml_site_map
    logger.info "xml_site_map"
    uris = Hash.new
    sitemap_count = 1

    AuthorService.all_authors_paged do |authors|
      authors.each do |author|
        next if author.nil?
        next if author.to_param.match(/\.json\z/)
        next if author.to_param.match(/\.xml\z/)
        next if author.to_param.match(/\.js\z/)
        next if author.to_param.match(/\.css\z/)
        next if author.to_param.match(/\.html\z/)

        uri = "authors/#{author.to_param}"
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
