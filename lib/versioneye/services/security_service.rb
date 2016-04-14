class SecurityService < Versioneye::Service


  def self.mark_versions sv, product, affected_versions
    return nil if sv.nil?
    return nil if product.nil?
    return nil if affected_versions.to_a.empty?

    affected_versions.each do |version|
      next if version.to_s.match(/\Adev\-/)

      if !sv.affected_versions.include?(version.to_s)
        sv.affected_versions.push(version.to_s)
      end

      product.reload
      product.add_svid version.to_s, sv
    end
  end


end