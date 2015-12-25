class LwlCsvService < LwlService


  def self.process_all projects, lwl, cwl, flatten = true, write_to_disk = false
    violations = []
    unknowns   = []
    csv_string = CSV.generate do |csv|
      projects.each do |project|
        fill_dto project, flatten
        csv << ['', '', '', '']
        csv << ["Project:", "#{project.name} (#{project.ids})", '', '']
        csv << ["Status", "Component", "Version", "License"]
        fill_components project, csv
        fill_list project, violations, :violated
        fill_list project, unknowns, :unknown
      end
      fill_license_whitelist lwl, csv
      fill_component_whitelist cwl, csv
      attach_list violations, "Violations", csv
      attach_list unknowns, "Unknowns", csv
    end
    csv_string
  end


  def self.process project, exclude_kids = false, flatten = true, write_to_disk = false
    fill_dto project, flatten
    csv_string = CSV.generate do |csv|
      csv << ['', '', '', '']
      csv << ["Project:", "#{project.name} (#{project.ids})", '', '']
      csv << ["Status", "Component", "Version", "License"]
      fill_components project, csv
      fill_license_whitelist project.license_whitelist, csv
      fill_component_whitelist project.component_whitelist, csv
    end
    csv_string
  end


  private


    def self.fill_list project, list, list_key
      project.lwl_pdf_list[list_key].each do |dep|
        comp_name = cal_name dep
        version = calc_version dep
        project_name = "#{project.name} (#{project.ids})"
        key = "violated__#{comp_name}__#{version}__#{dep[:license]}__#{project_name}"
        next if list.include?(key)
        list << key
      end
    end


    def self.fill_components project, csv
      [:whitelisted, :unknown, :violated].each do |key|
        project.lwl_pdf_list[key].each do |dep|
          comp_name = cal_name dep
          version = calc_version dep
          csv << [key, comp_name, version, dep[:license]]
        end
      end
    end


    def self.fill_license_whitelist lwl, csv
      return nil if lwl.nil? || lwl.license_elements.empty?

      csv << ['', '', '', '']
      csv << ['License Whitelist', "#{lwl.name} (#{lwl.ids})", '', '']
      csv << ['Bill of materials:', '', '', '']
      lwl.license_elements.each do |lwle|
        csv << ['', lwle.name, '', '']
      end
    end


    def self.fill_component_whitelist cwl, csv
      return nil if cwl.nil? || cwl.components.empty?

      csv << ['', '', '', '']
      csv << ['Component Whitelist', "#{cwl.name} (#{cwl.ids})", '', '']
      csv << ['Bill of materials:', '', '', '']
      cwl.components.each do |component|
        csv << ['', component.to_s, '', '']
      end
    end


    def self.attach_list violations, header, csv
      return nil if violations.nil? || violations.empty?

      csv << ['', '', '', '']
      csv << [header, '', '', '']
      csv << ["Status", "Component", "Version", "License", "Project"]
      violations.each do |key|
        line = key.split("__")
        csv << [line[0], line[1], line[2], line[3], line[4]]
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
