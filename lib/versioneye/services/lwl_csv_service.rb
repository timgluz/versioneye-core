class LwlCsvService < LwlService


  def self.process project, exclude_kids = false, flatten = true, write_to_disk = false
    fill_dto project, flatten

    csv_string = CSV.generate do |csv|
      csv << ["Status", "Component", "Version", "License"]
      fill_components project, csv
      fill_license_whitelist project, csv
      fill_component_whitelist project, csv
    end
    csv_string
  end


  private


    def self.fill_components project, csv
      [:whitelisted, :unknown, :violated].each do |key|
        project.lwl_pdf_list[key].each do |dep|
          comp_name = cal_name dep
          version = calc_version dep
          csv << [key, comp_name, version, dep[:license]]
        end
      end
    end


    def self.fill_license_whitelist project, csv
      return nil if project.license_whitelist.nil? || project.license_whitelist.license_elements.empty?

      csv << ['', '', '', '']
      csv << ['License Whitelist', "#{project.license_whitelist.name} (#{project.license_whitelist.id})", '', '']
      csv << ['Bill of materials:', '', '', '']
      project.license_whitelist.license_elements.each do |lwle|
        csv << ['', lwle.name, '', '']
      end
    end


    def self.fill_component_whitelist project, csv
      return nil if project.component_whitelist.nil? || project.component_whitelist.components.empty?

      csv << ['', '', '', '']
      csv << ['Component Whitelist', "#{project.component_whitelist.name} (#{project.component_whitelist.id})", '', '']
      csv << ['Bill of materials:', '', '', '']
      project.component_whitelist.components.each do |component|
        csv << ['', component.to_s, '', '']
      end
    end


    def self.cal_name dep
      language = dep[:language]
      comp_name = dep[:component]
      if dep[:group_id]
        comp_name = "#{dep[:group_id]}/#{dep[:component]}"
      end
      "(#{language}) #{comp_name}"
    end


    def self.calc_version dep
      version = ''
      if dep[:version].to_s.strip.match(/\A\:path/)
        version = ':path'
      elsif dep[:version].to_s.strip.match(/\A\:git/)
        version = ':git'
      else
        version = dep[:version].to_s.strip
      end
      version
    end


end
