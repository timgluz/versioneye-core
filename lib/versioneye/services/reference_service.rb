class ReferenceService < Versioneye::Service


  def self.find_by language, prod_key
    if Settings.instance.respond_to? "references_live_update"
      self.update_reference language, prod_key
    end

    Reference.find_by language, prod_key
  end


  def self.update_reference language, prod_key
    return if Settings.instance.references_live_update == false

    product = Product.fetch_product language, prod_key
    ProductService.update_used_by_count product, true
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end
