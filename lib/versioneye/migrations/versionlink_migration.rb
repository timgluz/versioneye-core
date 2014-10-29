class VersionlinkMigration < Versioneye::Service


  def self.migrate_clojure_links
    Versionlink.where(:language => "Java").each do |link|
      next if link.product

      product = Product.fetch_product("Clojure", link.prod_key)
      next if product.nil?

      begin
        p "Clojure / #{link.prod_key}"
        link.language = product.language
        link.save
      rescue => e
        p e.message
        link.remove
      end
    end
  end


end
