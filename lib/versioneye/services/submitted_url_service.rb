class SubmittedUrlService < Versioneye::Service

  def self.update_integration_statuses()
    SubmittedUrl.as_not_integrated.each do |submitted_url|
      update_integration_status submitted_url
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def self.update_integration_status( submitted_url )
    resource = submitted_url.product_resource
    return false if resource.nil? || resource.prod_key.nil?

    product = Product.fetch_product( resource.language, resource.prod_key )
    return false if product.nil?

    submitted_url.integrated = true
    if submitted_url.save
      SubmittedUrlMailer.integrated_url_email(submitted_url, product).deliver
      return true
    end

    log.error "Failed to update integration status for submittedUrl.#{submitted_url._id}"
    log.error submitted_url.errors.full_messages.to_sentence
    false
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    false
  end

end
