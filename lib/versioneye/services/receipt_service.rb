class ReceiptService < Versioneye::Service

  def self.process_receipts
    count = User.where(:plan_id.ne => nil).count
    return nil if count == 0

    per_page = 50
    skip = 0
    iterations = count / per_page
    iterations += 1

    (0..iterations).each do |i|
      customers = User.where(:plan_id.ne => nil).skip(skip).limit(per_page)

      handle_customers( customers )

      skip += per_page
    end
  end

  def self.handle_customers( customers )
    return nil if customers.nil? || customers.empty?
    customers.each do |customer|
      p customer
    end
  end

end
