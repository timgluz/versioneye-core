class LicenseWhitelistFactory

  def self.create_new name, licenses = [], user, orga
    whitelist = LicenseWhitelist.new :name => name
    if licenses && !licenses.empty?
      licenses.each do |license_name|
        whitelist.add_license_element license_name
      end
    end
    whitelist.user = user
    whitelist.organisation = orga
    whitelist
  end

end
