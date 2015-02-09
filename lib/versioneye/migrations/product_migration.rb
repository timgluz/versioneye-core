class ProductMigration < Versioneye::Service 

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

end 
