class ReceiptService < Versioneye::Service


  def self.process_receipts
    count = User.where(:plan_id.ne => nil).count
    return nil if count == 0

    per_page = 50
    skip = 0
    iterations = count / per_page
    iterations += 1

    (0..iterations).each do |i|
      users = User.where(:plan_id.ne => nil).skip(skip).limit(per_page)
      handle_users( users )
      skip += per_page
    end
  end


  def self.handle_users( users )
    return nil if users.nil? || users.empty?
    users.each do |user|
      handle_user( user )
    end
  end


  def self.handle_user( user )
    p user.to_s
  end


end
