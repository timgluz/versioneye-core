class PlanToOrgaMigration < Versioneye::Service

  def self.migrate
    Plan.current_plans.each do |plan|
      next if plan.name_id.eql?(Plan::A_PLAN_FREE)
      next if plan.name.eql?("Free")

      plan.users.each do |user|
        next if user.deleted_user

        orgas = OrganisationService.index user, true
        next if orgas.count > 1
        next if orgas.count == 0

        orga = orgas.first
        orga.stripe_token = user.stripe_token
        orga.stripe_customer_id = user.stripe_customer_id
        orga.plan = user.plan
        success = orga.save
        p "plan migration for user #{user.username} to orga #{orga.name} was a #{success}"

        ba         = user.fetch_or_create_billing_address
        ba.email   = user.email if ba.email.to_s.empty?
        ba.street  = '' if ba.street.to_s.empty?
        ba.zip     = '' if ba.zip.to_s.empty?
        ba.city    = '' if ba.city.to_s.empty?
        ba.country = '' if ba.country.to_s.empty?
        ba.organisation_id = orga.ids
        suc = ba.save
        p "billing_address migration for #{user.username} was a #{suc}"

        if success
          Receipt.where(:user_id => user.ids).each do |receipt|
            receipt.organisation_id = orga.ids
            receipt.save
          end
        end
        p "---"
      end
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

end
