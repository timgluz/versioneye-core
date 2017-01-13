class LicenseService < Versioneye::Service


  def self.search name
    result1 = SpdxLicense.where(:fullname => /#{name}/i)
    result2 = SpdxLicense.where(:identifier => /#{name}/i)
    keys = []
    results = []
    result1.map{|lic| results << lic; keys << lic.identifier } if result1 && !result1.empty?
    result2.map{|lic| results << lic if !keys.include?(lic.identifier) } if result2 && !result2.empty?
    results
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
    []
  end


  def self.import_from file_path
    content = File.read(file_path)
    content.split("\r").each do |line|
      cols = line.split(";")
      create_spdx_license cols[0], cols[1], cols[2]
    end
  end


  def self.import_from_properties_file file_path
    z = 0
    content = File.read(file_path)
    content.split("\n").each do |line|
      next if line.to_s.empty?

      sps = line.split("=")
      gav = sps[0]
      lic = sps[1]
      group_id     = gav.split("|")[0]
      artifact_id  = gav.split("|")[1]
      license_name = lic.split("|")[0]
      license_link = lic.split("|")[1]
      # p "#{group_id}:#{artifact_id} - #{license_name} - #{license_link}"
      product = Product.find_by_group_and_artifact group_id.downcase, artifact_id.downcase
      if product
        z +=1
        p "#{z} - #{license_name} - #{group_id}:#{artifact_id} - #{license_link}"

        product.versions.each do |version|
          product.version = version.to_s
          next if !product.licenses.empty?

          license = License.find_or_create product.language, product.prod_key, version.to_s, license_name, license_link
          p " - created new license #{license.to_s}"
        end
      else
        # z +=1
        # p "#{z} - product not found for #{group_id}/#{artifact_id}"
      end
    end
  end


  def self.import_websites_from_properties_file file_path
    z = 0
    content = File.read(file_path)
    content.split("\n").each do |line|
      next if line.to_s.empty?

      sps = line.split("=")
      gav = sps[0]
      link = sps[1]
      group_id     = gav.split("|")[0]
      artifact_id  = gav.split("|")[1]

      product = Product.find_by_group_and_artifact group_id.downcase, artifact_id.downcase
      if product
        z +=1
        p "#{z} - #{group_id}:#{artifact_id} - #{link}"

        vl = Versionlink.create_project_link( product.language, product.prod_key, link, "Website" )

        p " - created new verisonlink #{vl.to_s}"
      else
        # z +=1
        # p "#{z} - product not found for #{group_id}/#{artifact_id}"
      end
    end
  end


  def self.update_spdx_ids v = "1.0.0"
    all_licenses_paged(v) do |licenses|
      licenses.each do |license|
        license.spdx_id = license.spdx_identifier
        license.update_version = v
        license.save
      end
    end
    true
  rescue => e
    log.error e.message
    log.error e.backtrace.join('\n')
    update_spdx_ids v
  end


  def self.all_licenses_paged(v = "1.0.0")
    count = License.count()
    page = 100
    iterations = count / page
    iterations += 1
    (0..iterations).each do |i|
      skip = i * page
      licenses = License.where(:update_version.ne => v).skip(skip).limit(page)

      yield licenses

      co = i * page
      log.info "all_licenses_paged iteration: #{i} - licenses processed: #{co}"
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


  private


    def self.create_spdx_license name, identifier, approved
      spdx = SpdxLicense.new :fullname => name, :identifier => identifier, :osi_approved => approved
      spdx.save
    rescue => e
      p e.message
    end


end
