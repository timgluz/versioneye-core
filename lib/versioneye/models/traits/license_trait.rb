module VersionEye
  module LicenseTrait

    # http://spdx.org/licenses/

    def name_substitute
      return 'unknown' if name.to_s.empty?

      tmp_name = name.gsub(/\AThe /i, "").gsub(" - ", " ").gsub(", ", " ").gsub("Licence", "License").strip

      return 'MIT' if mit_match( tmp_name )

      return 'Ruby' if ruby_match( tmp_name )

      return 'JSON' if json_match( tmp_name )

      return 'CPL-1.0' if cpl_10_match( tmp_name ) # Common Public License 1.0

      return 'MPL-1.0'  if mpl_10_match( tmp_name )
      return 'MPL-1.1'  if mpl_11_match( tmp_name )
      return 'MPL-2.0'  if mpl_20_match( tmp_name )

      return 'CDDL-1.0' if cddl_match( tmp_name )
      return 'CDDL-1.1' if cddl_11_match(  tmp_name )
      return 'CDDL+GPL' if cddl_plus_gpl( tmp_name )

      return 'LGPL-2.0'  if lgpl_20_match( tmp_name )
      return 'LGPL-2.1'  if lgpl_21_match( tmp_name )
      return 'LGPL-3.0'  if lgpl_3_match( tmp_name )
      return 'LGPL-3.0+' if lgpl_3_or_later_match( tmp_name )

      return 'GPL'     if gpl_match( tmp_name )
      return 'GPL-1.0' if gpl_10_match( tmp_name )
      return 'GPL-2.0' if gpl_20_match( tmp_name )
      return 'GPL-3.0' if gpl_30_match( tmp_name )

      return 'AGPL-3.0' if agpl_30_match( tmp_name )

      return 'Apache-1.0' if apache_license_10_match( tmp_name )
      return 'Apache-1.1' if apache_license_11_match( tmp_name )
      return 'Apache-2.0' if apache_license_20_match( tmp_name )

      return 'EPL-1.0' if eclipse_match( tmp_name ) # Eclipse Public License 1.0
      return 'Eclipse Distribution License 1.0' if eclipse_distribution_match( tmp_name )

      return 'Artistic-1.0' if artistic_10_match( tmp_name )
      return 'Artistic-2.0' if artistic_20_match( tmp_name )

      return 'BSD 2-clause'  if bsd_2_clause_match( tmp_name )
      return 'BSD 3-clause' if bsd_3_clause_match( tmp_name )
      return 'BSD style' if bsd_style_match( tmp_name )
      return 'New BSD' if new_bsd_match( tmp_name )
      return 'BSD' if bsd_match( tmp_name )

      spdx = SpdxLicense.where(:fullname => /\A#{name}\z/i ).first
      return spdx.identifier if spdx 

      spdx = SpdxLicense.where(:identifier => /\A#{name}\z/i ).first
      return spdx.identifier if spdx

      name.gsub("Licence", "License")
    end

    def json_match name
      name.match(/\AJSON\z/i) ||
      name.match(/\AJSON license\z/i)
    end

    def mpl_10_match name
      name.match(/\AMozilla Public License Version 1\.0\z/i) ||
      name.match(/\AMozilla Public License 1\.0\z/i) ||
      name.match(/\AMPL\-1\.0\z/i) ||
      name.match(/\AMPL 1\.0\z/i)
    end

    def mpl_11_match name
      name.match(/\AMozilla Public License Version 1\.1\z/i) ||
      name.match(/\AMozilla Public License 1\.1\z/i) ||
      name.match(/\AMozilla Public License 1\.1 \(MPL 1\.1\)\z/i) ||
      name.match(/\AMPL\-1\.1\z/i) ||
      name.match(/\AMPL 1\.1\z/i)
    end

    def mpl_20_match name
      name.match(/\AMozilla Public License 2\.0\z/i) ||
      name.match(/\AMozilla Public License Version 2\.0\z/i) ||
      name.match(/\AMozilla Public License 2\.0 \(MPL 2\.0\)\z/i) ||
      name.match(/\AMPL\-2\.0\z/i) ||
      name.match(/\AMPL 2\.0\z/i)
    end

    def ruby_match name
      name.match(/\ARuby\z/i) ||
      name.match(/\ARuby 1\.8\z/i) ||
      name.match(/\ARuby License\z/i)
    end

    def mit_match name
      name.match(/\AMIT\z/i) ||
      name.match(/\AMIT License\z/i) || 
      name.match(/\AMIT License \(MIT\)\z/i)
    end

    def eclipse_match name
      name.match(/\AEPL\z/i) ||
      name.match(/\AEclipse\z/i) ||
      name.match(/\AEclipse License\z/i) ||
      name.match(/\AEclipse Public License\z/i) ||
      name.match(/\AEclipse Public License 1\.0\z/i) ||
      name.match(/\AEclipse Public License v1\.0\z/i) ||
      name.match(/\AEclipse Public License v 1\.0\z/i) ||
      name.match(/\AEclipse Public License Version 1\.0\z/i) ||
      name.match(/\AEclipse Public License Version 1\.0\z/i)
    end

    def eclipse_distribution_match name
      name.match(/\AEclipse Distribution\z/i) ||
      name.match(/\AEclipse Distribution License v\. 1\.0\z/i) ||
      name.match(/\AEclipse Distribution License 1\.0\z/i) ||
      name.match(/\AEclipse Distribution License v1\.0\z/i) ||
      name.match(/\AEclipse Distribution License v 1\.0\z/i) ||
      name.match(/\AEclipse Distribution License Version 1\.0\z/i) ||
      name.match(/\AEclipse Distribution License Version 1\.0\z/i)
    end

    def bsd_match name
      name.match(/\ABSD\z/) ||
      name.match(/\ABSD License\z/i)
    end

    def bsd_style_match name
      name.match(/\ABSD style\z/i) ||
      name.match(/\ABSD style License\z/i) ||
      name.match(/\ABSD-style License\z/i)
    end

    def new_bsd_match name
      name.match(/\ANew BSD\z/i) ||
      name.match(/\ANew BSD License\z/i)
    end

    def bsd_2_clause_match name
      name.match(/BSD 2-Clause/i) ||
      name.match(/BSD-2-Clause/i) ||
      name.match(/BSD-2 Clause/i) ||
      name.match(/BSD 2 Clause/i)
    end

    def bsd_3_clause_match name
      name.match(/BSD 3 Clause/i) ||
      name.match(/BSD 3-Clause/i) ||
      name.match(/BSD-3-Clause/i) ||
      name.match(/\ARevised BSD\z/i) ||
      name.match(/\ABSD Revised\z/i) ||
      name.match(/\ABSD New\z/i)
    end

    def gpl_match name
      name.match(/\AGPL\z/i) ||
      name.match(/\AGNU General Public Library\z/i) || 
      name.match(/\AGNU General Public License \(GPL\)\z/i)
    end

    def gpl_10_match name
      name.match(/\AGPL1\z/i) ||
      name.match(/\AGPL 1\z/i) ||
      name.match(/\AGPL\-1\z/i) ||
      name.match(/\AGPLv1\+\z/i) ||
      name.match(/\AGPL 1\.0\z/i) ||
      name.match(/\AGPL\-1\.0\z/i) ||
      name.match(/\AGNU General Public License version 1 \(GPL\-1\.0\)\z/i) ||
      name.match(/\AGNU General Public License \(GPL\-1\.0\)\z/i) ||
      name.match(/\AGNU General Public License 1\.0\z/i) ||
      name.match(/\AGNU General Public License Version 1\z/i) ||
      name.match(/\AGNU General Public License v1\.0 only\z/i) ||
      name.match(/\AGeneral Public License 1\.0\z/i)
    end

    def gpl_20_match name
      name.match(/\AGPL2\z/i) ||
      name.match(/\AGPL 2\z/i) ||
      name.match(/\AGPL\-2\z/i) ||
      name.match(/\AGPLv2\+\z/i) ||
      name.match(/\AGPL 2\.0\z/i) ||
      name.match(/\AGPL\-2\.0\z/i) ||
      name.match(/\AGNU GPL v2/i) ||
      name.match(/\AGNU General Public License version 2 \(GPL\-2\.0\)\z/i) ||
      name.match(/\AGNU General Public License \(GPL\-2\.0\)\z/i) ||
      name.match(/\AGNU General Public License 2\.0\z/i) ||
      name.match(/\AGNU General Public License Version 2\z/i) ||
      name.match(/\AGNU General Public License v2\.0 only\z/i) || 
      name.match(/\AGeneral Public License 2\.0\z/i)
    end

    def gpl_30_match name
      name.match(/\AGPL3\z/i) ||
      name.match(/\AGPL 3\z/i) ||
      name.match(/\AGPL\-3\z/i) ||
      name.match(/\AGPLv3\+\z/i) ||
      name.match(/\AGPL 3\.0\z/i) ||
      name.match(/\AGPL\-3\.0\z/i) ||
      name.match(/\AGNU General Public License version 3 \(GPL\-3\.0\)\z/i) ||
      name.match(/\AGNU General Public License version 3 \(GPL\-3\.0\)\z/i) ||
      name.match(/\AGNU General Public License \(GPL\-3\.0\)\z/i) ||
      name.match(/\AGNU General Public License 3\.0\z/i) ||
      name.match(/\AGNU General Public License Version 3\z/i) ||
      name.match(/\AGNU General Public License v3\.0 only\z/i) ||
      name.match(/\AGeneral Public License 3\.0\z/i)
    end

    def agpl_30_match name
      name.match(/\AAGPL3\z/i) ||
      name.match(/\AAGPL 3\z/i) ||
      name.match(/\AAGPL\-3\z/i) ||
      name.match(/\AAGPLv3\+\z/i) ||
      name.match(/\AAGPL 3\.0\z/i) ||
      name.match(/\AAGPL\-3\.0\z/i) ||
      name.match(/\AGNU AFFERO General Public License version 3 \(AGPL\-3\.0\)\z/i) ||
      name.match(/\AGNU AFFERO General Public License version 3 \(AGPL\-3\.0\)\z/i) ||
      name.match(/\AGNU AFFERO General Public License \(AGPL\-3\.0\)\z/i) ||
      name.match(/\AGNU AFFERO General Public License 3\.0\z/i) ||
      name.match(/\AGNU AFFERO General Public License Version 3\z/i) ||
      name.match(/\AAFFERO General Public License 3\.0\z/i) ||
      name.match(/\AAFFERO General Public License 3\z/i)
    end

    def lgpl_20_match name
      name.match(/\ALGPL2\z/i) ||
      name.match(/\ALGPL 2\z/i) ||
      name.match(/\ALGPLv2\z/i) ||
      name.match(/\ALGPL\-2\z/i) ||
      name.match(/\ALGPL version 2\.0\z/i) ||
      name.match(/\ALGPL v2.0\z/i) ||
      name.match(/\ALGPL 2\.0\z/i) ||
      name.match(/\ALGPLv2\.0\z/i) ||
      name.match(/\ALGPL\-2\.0\z/i) ||
      name.match(/\AGNU Lesser General Public License v2\.0 only\z/i) ||
      name.match(/\AGNU Lesser General Public License Version 2\.0\z/i)
    end

    def lgpl_21_match name
      name.match(/\ALGPL version 2\.1\z/i) ||
      name.match(/\ALGPL v2.1\z/i) ||
      name.match(/\ALGPL 2\.1\z/i) ||
      name.match(/\ALGPLv2\.1\z/i) ||
      name.match(/\ALGPL\-2\.1\z/i) ||
      name.match(/\AGNU Lesser General Public License v2\.1 only\z/i) ||
      name.match(/\AGNU Lesser General Public License Version 2\.1\z/i) ||
      name.match(/\AGNU Lesser General Public License \(LGPL\) Version 2\.1\z/i)
    end

    def lgpl_3_match name
      name.match(/\ALGPL 3\z/i) ||
      name.match(/\ALGPLv3\z/i) ||
      name.match(/\ALGPL\-3\z/i) ||
      name.match(/\ALGPL\z/i) ||
      name.match(/\AGnu Lesser Public License\z/i) ||
      name.match(/\AGNU LESSER GENERAL PUBLIC LICENSE\z/i) ||
      name.match(/\AGNU Lesser General Public License v3\.0 only\z/i) || 
      name.match(/\AGNU Library or Lesser General Public License \(LGPL\)\z/i)
    end

    def lgpl_3_or_later_match name
      name.match(/\ALGPL 3\+\z/i) ||
      name.match(/\ALGPLv3\+\z/i) ||
      name.match(/\ALGPL\-3\+\z/i) ||
      name.match(/\AGNU Lesser General Public License v3\.0 or later\z/i)
    end

    def artistic_10_match name
      name.match(/\AArtistic 1\.0\z/i) ||
      name.match(/\AArtistic\-1\.0\z/i) ||
      name.match(/\AArtistic License\z/i) ||
      name.match(/\AArtistic License 1\.0\z/i)
    end

    def artistic_20_match name
      name.match(/\AArtistic 2.0\z/) ||
      name.match(/\AArtistic\-2.0\z/) ||
      name.match(/\AArtistic License 2.0\z/i)
    end

    def apache_license_10_match name
      name.match(/\AApache 1\z/i) ||
      name.match(/\AApache\-1\z/i) ||
      name.match(/\AApache 1\.0\z/i) ||
      name.match(/\AApache\-1\.0\z/i) ||
      name.match(/\AApache License 1\z/i) ||
      name.match(/\AApache License 1\.0\z/i) ||
      name.match(/\AApache License V1\.0\z/i) ||
      name.match(/\AApache License Version 1\.0\z/i) ||
      name.match(/\AApache Software License Version 1\.0\z/i)
    end

    def apache_license_11_match name
      name.match(/\AApache 1\.1\z/i) ||
      name.match(/\AApache\-1\.1\z/i) ||
      name.match(/\AApache License 1\.1\z/i) ||
      name.match(/\AApache License V1\.1\z/i) ||
      name.match(/\AApache License Version 1\.1\z/i) ||
      name.match(/\AApache Software License Version 1\.1\z/i)
    end

    def apache_license_20_match name
      name.match(/\AASF 2\.0\z/i) ||
      name.match(/\AASF-2\.0\z/i) ||
      name.match(/\AASF-2\z/i) ||
      name.match(/\AASF 2\z/i) ||
      name.match(/\AASL 2\.0\z/i) ||
      name.match(/\AApache\z/i) ||
      name.match(/\AApache 2\z/i) ||
      name.match(/\AApache\-2\z/i) ||
      name.match(/\AApache 2\.0\z/i) ||
      name.match(/\AApache\-2\.0\z/i) ||
      name.match(/\AApache License\z/i) ||
      name.match(/\AApache License 2\z/i) ||
      name.match(/\AApache License 2\.0\z/i) ||
      name.match(/\AApache License V2\.0\z/i) ||
      name.match(/\AApache License Version 2\.0\z/i) ||
      name.match(/\AApache Public License 2\.0\z/i) ||
      name.match(/\AApache Software License\z/i) ||
      name.match(/\AApache Software Licenses\z/i) ||
      name.match(/\AApache Software License Version 2\.0\z/i) ||
      name.match(/\AApache License ASL Version 2\.0/i) ||
      name.match(/\AApache License ASL Version 2/i)
    end

    def cddl_match name
      name.match(/\ACDDL\z/i) ||
      name.match(/\ACDDL 1\.0\z/i) ||
      name.match(/\ACDDL\-1\.0\z/i) ||
      name.match(/\ACommon Development and Distribution License 1\.0\z/i) ||
      name.match(/\ACOMMON DEVELOPMENT AND DISTRIBUTION LICENSE \(CDDL\) Version 1\.0\z/i) ||
      name.match(/\ACommon Development and Distribution License \(CDDL\-1\.0\)\z/i) ||
      name.match(/\ACommon Development and Distribution License \(CDDL\) v1\.0\z/i)
    end

    def cddl_11_match name
      name.match(/\ACDDL 1\.1\z/i) ||
      name.match(/\ACDDL\-1\.1\z/i) ||
      name.match(/\ACommon Development and Distribution License 1\.1\z/i) ||
      name.match(/\ACOMMON DEVELOPMENT AND DISTRIBUTION LICENSE \(CDDL\) Version 1\.1\z/i) ||
      name.match(/\ACommon Development and Distribution License \(CDDL\-1\.1\)\z/i) ||
      name.match(/\ACommon Development and Distribution License \(CDDL\) v1\.1\z/i)
    end

    def cddl_plus_gpl name
      name.match(/\ACOMMON DEVELOPMENT AND DISTRIBUTION LICENSE \(CDDL\) plus GPL\z/i) ||
      name.match(/\ACDDL\+GPL License\z/i)
    end

    def cpl_10_match name
      name.match(/\ACPL 1\.0\z/i) ||
      name.match(/\ACPL\-1\.0\z/i) ||
      name.match(/\ACommon Public License 1\z/i) ||
      name.match(/\ACommon Public License 1\.0\z/i) ||
      name.match(/\ACommon Public License v 1\.0\z/i)
      name.match(/\ACommon Public License Version 1\z/i) ||
      name.match(/\ACommon Public License Version 1\.0\z/i)
      name.match(/\ACommon Public License Version 1\.0\z/i) ||
      name.match(/\ACommon Public License 1\.0\z/i) ||
      name.match(/\ACommon Public License v 1\.0\z/i)
    end

  end

end
