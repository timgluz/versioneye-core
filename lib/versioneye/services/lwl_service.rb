class LwlService < Versioneye::Service

  require 'pdfkit'
  require 'ostruct'


  def self.prepare_kids project, exclude_kids = false, flatten
    children = []
    return children if exclude_kids || flatten

    if project.children && !project.children.empty?
      project.children.each do |sub_project|
        fill_dto sub_project, false
        children << sub_project
      end
    end
    children
  end


  def self.fill_dto project, flatten = false
    uniq_array = []
    dto = { :whitelisted => [], :unknown => [], :violated => [] }

    fill_dto_with project.dependencies, dto, uniq_array, project.license_whitelist

    if flatten && project.children && !project.children.empty?
      project.children.each do |child|
        fill_dto_with child.dependencies, dto, uniq_array
      end
    end

    dto[:whitelisted].sort_by!{ |hsh| hsh[:component] }
    dto[:unknown].sort_by!{ |hsh| hsh[:component] }
    dto[:violated].sort_by!{ |hsh| hsh[:component] }
    project.lwl_pdf_list = dto
    dto
  end


  private


    def self.fill_dto_with dependencies, dto, uniq_array, license_whitelist = nil
      dependencies.each do |dep|
        if dep.license_caches && !dep.license_caches.empty?
          line_per_license( dep, dto, uniq_array, license_whitelist )
        else
          unknown_line( dep, dto, uniq_array )
        end
      end
    end


    def self.line_per_license dep, dto, uniq_array, license_whitelist = nil
      # whitelisted is true if a dependency has a dual/multi lincese and at least
      # one of them is on the license whitelist
      whitelisted = false
      lines = []

      dep.license_caches.each do |lc|
        line = build_line(dep)
        line[:license] = lc.name
        line[:whitelisted] = lc.is_whitelisted?
        lines << line
        whitelisted = true if lc.is_whitelisted?
      end

      lines.each do |line|
        uvalue = create_uniq_identifier(line)
        next if uniq_array.include?(uvalue)

        uniq_array << uvalue
        if line[:whitelisted] == true
          dto[:whitelisted] << line
          next
        end
        if line[:whitelisted] == false && license_whitelist && license_whitelist.pessimistic_mode == false && whitelisted
          next
        end
        dto[:violated] << line
      end
    end


    def self.unknown_line dep, dto, uniq_array
      line = build_line(dep)
      line[:license] = 'UNKNOWN'
      uvalue = create_uniq_identifier(line)
      if !uniq_array.include?(uvalue)
        dto[:unknown] << line
        uniq_array << uvalue
      end
    end


    def self.create_uniq_identifier line
      "#{line[:component]}_#{line[:group_id]}_#{line[:version]}_#{line[:license]}"
    end


    def self.build_line dep
      dep_name = dep.name
      dep_name = dep.artifact_id if !dep.artifact_id.to_s.empty?
      {:language => dep.language, :component => dep_name, :group_id => dep.group_id, :version => dep.version_requested}
    end


end
