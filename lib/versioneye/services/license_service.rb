class LicenseService < Versioneye::Service

  def self.search name
    SpdxLicense.where(:fullname => /#{name}/i)
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end

  def self.import_from file_path
    content = File.read(file_path)
    content.split("\r").each do |line|
      cols = line.split(";")
      create_spdx_license cols[0], cols[1], cols[2]
    end
  end

  private

    def self.create_spdx_license name, identifier, approved
      spdx = SpdxLicense.new :fullname => name, :identifier => identifier, :osi_approved => approved
      spdx.save
    rescue => e
      p e.message
    end

end
