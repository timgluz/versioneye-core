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

    fill_dto_with project.dependencies, dto, uniq_array

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


    def self.fill_dto_with dependencies, dto, uniq_array
      uvalue = ''
      dependencies.each do |dep|
        line = build_line(dep)
        if dep.license_caches && !dep.license_caches.empty?
          dep.license_caches.each do |lc|
            line[:license] = lc.name
            uvalue = create_uniq_identifier(line)
            next if uniq_array.include?(uvalue)

            dto[:whitelisted] << line if lc.is_whitelisted? == true
            dto[:violated]    << line if lc.is_whitelisted? == false
          end
        else
          line[:license] = 'UNKNOWN'
          uvalue = create_uniq_identifier(line)
          dto[:unknown] << line if !uniq_array.include?(uvalue)
        end

        uniq_array << uvalue if !uniq_array.include?(uvalue)
      end
    end


    def self.create_uniq_identifier line
      "#{line[:component]}_#{line[:group_id]}_#{line[:version]}_#{line[:license]}"
    end


    def self.build_line dep
      dep_name = dep.name
      dep_name = dep.artifact_id if !dep.artifact_id.to_s.empty?
      {:component => dep_name, :group_id => dep.group_id, :version => dep.version_requested}
    end


end
