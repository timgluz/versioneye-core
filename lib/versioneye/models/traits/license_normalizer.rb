module VersionEye
  module LicenseNormalizer

    
    def name_substitute
      identifier name 
    end

    
    def identifier name 
      return 'unknown' if name.to_s.empty?

      # return name if name.size > 100
      spdx_id = spdx_identifier
      return spdx_id if spdx_id

      name.gsub("Licence", "License")
    rescue => e 
      log.error e 
      log.error e.backtrace.join("\n")
      name 
    end

    
    # http://spdx.org/licenses/
    def spdx_identifier 
      tmp_name = do_replacements(name)

      return 'AGPL-3.0' if agpl_30_match( tmp_name )
      return 'AGPL-1.0' if agpl_10_match( tmp_name )

      return 'LGPL-2.1'  if lgpl_21_match( tmp_name )
      return 'LGPL-2.0'  if lgpl_20_match( tmp_name )
      return 'LGPL-3.0+' if lgpl_3_or_later_match( tmp_name )
      return 'LGPL-3.0'  if lgpl_3_match( tmp_name )

      return 'GPL'     if gpl_match( tmp_name )
      return 'GPL-1.0' if gpl_10_match( tmp_name )
      return 'GPL-2.0' if gpl_20_match( tmp_name )
      return 'GPL-3.0' if gpl_30_match( tmp_name )

      return 'CC-BY-SA-1.0' if cc_by_sa_10_match( tmp_name )
      return 'CC-BY-SA-2.0' if cc_by_sa_20_match( tmp_name )
      return 'CC-BY-SA-2.5' if cc_by_sa_25_match( tmp_name )
      return 'CC-BY-SA-3.0' if cc_by_sa_30_match( tmp_name )
      return 'CC-BY-SA-4.0' if cc_by_sa_40_match( tmp_name )

      return 'MIT' if mit_match( tmp_name )

      return 'Ruby' if ruby_match( tmp_name )

      return 'JSON' if json_match( tmp_name )

      return 'CPL-1.0' if cpl_10_match( tmp_name ) # Common Public License 1.0

      return 'MPL-1.1'  if mpl_11_match( tmp_name )
      return 'MPL-1.0'  if mpl_10_match( tmp_name )
      return 'MPL-2.0'  if mpl_20_match( tmp_name )

      return 'CDDL-1.1' if cddl_11_match(  tmp_name )
      return 'CDDL+GPL' if cddl_plus_gpl( tmp_name )
      return 'CDDL-1.0' if cddl_match( tmp_name )

      return 'Apache-1.1' if apache_license_11_match( tmp_name )
      return 'Apache-1.0' if apache_license_10_match( tmp_name )
      return 'Apache-2.0' if apache_license_20_match( tmp_name )

      return 'EPL-1.0' if eclipse_match( tmp_name ) # Eclipse Public License 1.0
      return 'EDL-1.0' if eclipse_distribution_match( tmp_name ) # Eclipse Distribution License 1.0

      return 'ClArtistic'         if clarified_artistic_match( tmp_name )
      return 'Artistic-1.0'       if artistic_10_match( tmp_name )
      return 'Artistic-1.0-Perl'  if artistic_10_perl( tmp_name )
      return 'Artistic-1.0-cl8'   if artistic_10_cl8( tmp_name )
      return 'Artistic-2.0'       if artistic_20_match( tmp_name )

      return 'BSD-4-Clause-UC'    if bsd_4_clause_UC_match( tmp_name )
      return 'BSD-4-Clause'       if bsd_4_clause_match( tmp_name )

      return 'BSD-3-Clause-Clear' if bsd_3_clause_clear_match( tmp_name )
      return 'BSD-3-Clause'       if bsd_3_clause_match( tmp_name )

      return 'BSD-2-Clause-NetBSD'  if bsd_2_clause_netbsd_match( tmp_name )
      return 'BSD-2-Clause-FreeBSD' if bsd_2_clause_freebsd_match( tmp_name )
      return 'BSD-2-Clause'         if bsd_2_clause_match( tmp_name )
      
      return 'BSD' if bsd_match( tmp_name )

      return 'PHP-3.01' if php_301_match( tmp_name )
      return 'PHP-3.0'  if php_30_match( tmp_name )

      spdx = SpdxLicense.identifier_by_fullname_regex name 
      return spdx.identifier if spdx 

      spdx = SpdxLicense.identifier_by_regex name
      return spdx.identifier if spdx

      nil 
    end


    def link
      if url && !url.empty?
        return url if url.match(/\Ahttp:\/\//xi) || url.match(/\Ahttps:\/\//xi)
        return "http://#{url}" if url.match(/\Awww\./xi)
      end
      return nil if name.to_s.empty?

      spdx_id = spdx_identifier 
      return "http://spdx.org/licenses/#{spdx_id}.html" if spdx_id
      
      return 'https://glassfish.java.net/nonav/public/CDDL+GPL.html' if cddl_plus_gpl( tmp_name )
      return 'http://www.eclipse.org/org/documents/edl-v10.php'  if eclipse_distribution_match( tmp_name )

      nil
    end


    def php_301_match name
      name.match(/\APHP\s+3.01\z/i) ||
      name.match(/\APHP\s+31\z/i)
    end

    def php_30_match name
      name.match(/\APHP\s*3\z/i) || 
      name.match(/\APHPv3\z/i)
    end

    # Creative Commons Attribution Share Alike 1.0
    def cc_by_sa_10_match name
      name.match(/\ACC\s+BY\s+SA\s+1\z/i) ||
      name.match(/\ACreative\s+Commons\s+Attribution\s+Share\s+Alike\s+1\z/i) || 
      name.match(/\ACreative\s+Commons\s+1\s+BY\s+SA\z/i) || 
      name.match(/\ACC\s+1\s+BY\s+SA\z/i) 
    end

    # Creative Commons Attribution Share Alike 2.0
    def cc_by_sa_20_match name
      name.match(/\ACC\s+BY\s+SA\s+2\z/i) ||
      name.match(/\ACreative\s+Commons\s+Attribution\s+Share\s+Alike\s+2\z/i) || 
      name.match(/\ACreative\s+Commons\s+2\s+BY\s+SA\z/i) || 
      name.match(/\ACC\s+2\s+BY\s+SA\z/i) 
    end

    # Creative Commons Attribution Share Alike 2.5
    def cc_by_sa_25_match name
      name.match(/\ACC\s+BY\s+SA\s+2\.5\z/i) ||
      name.match(/\ACreative\s+Commons\s+Attribution\s+Share\s+Alike\s+2\.5\z/i) || 
      name.match(/\ACreative\s+Commons\s+2\.5\s+BY\s+SA\z/i) || 
      name.match(/\ACC\s+2\.5\s+BY\s+SA\z/i) 
    end

    # Creative Commons Attribution Share Alike 3.0
    def cc_by_sa_30_match name
      name.match(/\ACC\s+BY\s+SA\s+3\z/i) ||
      name.match(/\ACreative\s+Commons\s+Attribution\s+Share\s+Alike\s+3\z/i) || 
      name.match(/\ACreative\s+Commons\s+3\s+BY\s+SA\z/i) || 
      name.match(/\ACC\s+3\s+BY\s+SA\z/i) 
    end

    # Creative Commons Attribution Share Alike 4.0
    def cc_by_sa_40_match name
      name.match(/\ACC\s+BY\s+SA\s+4\z/i) ||
      name.match(/\ACreative\s+Commons\s+Attribution\s+Share\s+Alike\s+4\z/i) || 
      name.match(/\ACreative\s+Commons\s+4\s+BY\s+SA\z/i) || 
      name.match(/\ACC\s+4\s+BY\s+SA\z/i) 
    end

    def json_match name
      name.match(/\AJSON\z/i)
    end

    def mpl_10_match name
      name.match(/\AMozilla\s*Public\s*1\z/i) ||
      name.match(/\AMozilla\s*Public\s*1\s*\(MPL\s*1\)\z/i) ||
      name.match(/\AMPL\s*1\z/i) || 
      name.match(/\AMPLv1\z/i)
    end

    def mpl_11_match name
      name.match(/\AMozilla\s+Public\s+1\.1\z/i) ||
      name.match(/\AMozilla\s+Public\s+1\.1\s+\(MPL\s+1\.1\)\z/i) ||
      name.match(/\AMPL\s*1\.1\z/i) || 
      name.match(/\AMPLv1\.1\z/i)
    end

    def mpl_20_match name
      name.match(/\AMozilla\s*Public\s*2\z/i) ||
      name.match(/\AMozilla\s*Public\s*2\s*\(MPL\s*2\)\z/i) ||
      name.match(/\AMPL\s*2\z/i) || 
      name.match(/\AMPLv2\z/i)
    end

    def ruby_match name
      name.match(/\ARuby\s+1\.8\z/i) ||
      name.match(/\ARuby\z/i)
    end

    def mit_match name
      name.match(/\AMIT\z/i) ||
      name.match(/\AMIT\s*style\z/i) ||
      name.match(/\AMIT-style\z/i) ||
      name.match(/\AMIT\s*\(MIT\)\z/i)
    end

    def eclipse_match name
      name.match(/\AEPL\z/i) ||
      name.match(/\AEPL\s*1\z/i) ||
      name.match(/\AEPLv1\z/i) ||
      name.match(/\AEPLv1\.1\z/i) ||
      name.match(/\AEclipse\z/i) ||
      name.match(/\AEclipse\s*Public\z/i) ||
      name.match(/\AEclipse\s*Public\s*1\z/i) ||
      name.match(/\AEclipse\s*Public\s*v1\z/i) ||
      name.match(/\AEclipse\s*Public\s*v\s*1\z/i) ||
      name.match(/\AEclipse\s*Public\s*1\z/i)
    end

    def eclipse_distribution_match name
      name.match(/\AEDL\s*1\z/i) ||
      name.match(/\AEDLv1\z/i) ||
      name.match(/\AEDLv1\.1\z/i) ||
      name.match(/\AEclipse\sE*Distribution\z/i) ||
      name.match(/\AEclipse\s*Distribution\s*v\.s*1\z/i) ||
      name.match(/\AEclipse\s*Distribution\s*1\z/i) ||
      name.match(/\AEclipse\s*Distribution\s*v1\z/i) ||
      name.match(/\AEclipse\s*Distribution\s*vs*1\z/i) ||
      name.match(/\AEclipse\s*Distribution\s*1\z/i)
    end

    def bsd_match name
      tmp_name = name.gsub("-", " ").strip 
      tmp_name.match(/\ABSD\z/) ||
      tmp_name.match(/\ABSD\z/i) || 
      tmp_name.match(/\ABSD\s*style\z/i) ||
      tmp_name.match(/\ABSD\s*like\z/i) 
    end

    def bsd_2_clause_match name
      tmp_name = name.gsub("-", " ").strip 
      tmp_name.match(/BSD\s*2\s*Clause/i) || 
      tmp_name.match(/BSD\s*2\s*clause\s*\"Simplified\"/i) || 
      tmp_name.match(/BSD\s*2\s*clause\s*Simplified/i) || 
      tmp_name.match(/2\s*clause\s*BSD/i) || 
      tmp_name.match(/2\s*clause\s*BSDL/i) || 
      tmp_name.match(/Simplified\s*BSD/i) 
    end

    def bsd_2_clause_freebsd_match name
      tmp_name = name.gsub("-", " ").strip 
      tmp_name.match(/BSD\s*2\s*Clause\s*FreeBSD/i) || 
      tmp_name.match(/BSD\s*2\s*FreeBSD/i) || 
      tmp_name.match(/FreeBSD/i) 
    end

    def bsd_2_clause_netbsd_match name
      tmp_name = name.gsub("-", " ").strip 
      tmp_name.match(/BSD\s*2\s*clause\s*NetBSD/i) || 
      tmp_name.match(/BSD\s*2\s*NetBSD/i) 
    end

    def bsd_3_clause_match name
      tmp_name = name.gsub("-", " ").strip 
      tmp_name.match(/BSD\s*3/i) ||
      tmp_name.match(/BSDv3/i) ||
      tmp_name.match(/BSDv3.0/i) ||
      tmp_name.match(/BSD\s*3\s*Clause\s*new/i) ||
      tmp_name.match(/BSD\s*3\s*Clause\s*Revised/i) ||
      tmp_name.match(/BSD\s*3\s*Clause/i) ||
      tmp_name.match(/3\s*clause\s*BSD/i) ||
      tmp_name.match(/3\s*clause\s*BSDL/i) ||
      tmp_name.match(/\ARevised\s*BSD\z/i) ||
      tmp_name.match(/\ARevised\s*BSDL\z/i) ||
      tmp_name.match(/\ANew\s*BSD\z/i) || 
      tmp_name.match(/\ABSD\s*Revised\z/i) ||
      tmp_name.match(/\ABSD\s*New\z/i) || 
      tmp_name.match(/\ABSD\s*3\s*clause\s*\"New\"\s*or\s*\"Revised\"\z/i)
    end

    def bsd_3_clause_clear_match name 
      new_name = name.gsub("-", " ").strip 
      return true if new_name.match(/BSD 3 Clause Clear/i)
      return true if new_name.match(/Clear BSD/i)
      return false 
    end


    def bsd_4_clause_UC_match name
      tmp_name = name.gsub("-", " ").strip 
      tmp_name.match(/BSD\s*4\s*clause\s+\(University\s+of\s+California\s+Specific\)/i) ||
      tmp_name.match(/BSD\s*4\s*clause\s+\(University\s+of\s+California\)/i) ||
      tmp_name.match(/BSD\s*4\s+UC/i) ||
      tmp_name.match(/BSD\s*4\s+clause\s+UC/i)
    end

    def bsd_4_clause_match name
      tmp_name = name.gsub("-", " ").strip 
      tmp_name.match(/BSD\s*4\s*clause/i) ||
      tmp_name.match(/BSD\s*4/i) ||
      tmp_name.match(/4\s*clause\s*BSD/i) ||
      tmp_name.match(/BSD\s*4-clause\s*\"Original\"\s*or\s*\"Old\"/i) ||
      tmp_name.match(/original BSD/i) ||
      tmp_name.match(/old BSD/i)
    end

    def gpl_match name
      name.match(/\AGPL\z/i) ||
      name.match(/\AGNU\s+General\s+Public\s+Library\z/i) || 
      name.match(/\AGNU\s+General\s+Public\s+\(GPL\)\z/i)
    end

    def gpl_10_match name
      new_name = name.gsub(/gnu/i, "").strip 
      new_name.match(/\AGPL1\z/i) ||
      new_name.match(/\AGPL\s+1\z/i) ||
      new_name.match(/\AGPLv1\+\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+1\s+\(GPL\s+1\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+\(GPL\s+1\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+1\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+1\s+only\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+1\z/i)
    end

    def gpl_20_match name
      new_name = name.gsub(/gnu/i, "").strip 
      new_name.match(/\AGPL\s*2\z/i) ||
      new_name.match(/\AGPLv2\+\z/i) ||
      new_name.match(/\AGPLv2\.0\+\z/i) ||
      new_name.match(/\AGPL2\+\z/i) ||
      new_name.match(/\AGPL\s*2\+\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+2\s+\(GPL\s+2\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+\(GPL\s+2\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+2\s+only\z/i) || 
      new_name.match(/\AGeneral\s+Public\s+2\z/i)
    end

    def gpl_30_match name 
      new_name = name.gsub(/gnu/i, "").strip 
      new_name.match(/\AGPL3\z/i) ||
      new_name.match(/\AGPL\s*3\z/i) ||
      new_name.match(/\AGPLv3\+\z/i) ||
      new_name.match(/\AGPLv3\.*\+\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+3\s+\(GPL\s+3\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+\(GPL\s+3\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+3\s+only\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+3\z/i)
    end

    def agpl_10_match name
      new_name = name.gsub(/gnu/i, "").strip
      new_name.match(/\AAGPL\s*1\z/i) ||
      new_name.match(/\AAGPLv1\z/i) ||
      new_name.match(/\AAGPLv1.0\+\z/i) ||
      new_name.match(/\AAFFERO\s+General\s+Public\s*3\s*\(AGPL\s*1\)\z/i) ||
      new_name.match(/\AAFFERO\s+General\s+Public\s*\(AGPL\s*1\)\z/i) ||
      new_name.match(/\AAFFERO\s+General\s+Public\s*1\z/i)
    end

    def agpl_30_match name
      new_name = name.gsub(/gnu/i, "").strip
      new_name.match(/\AAGPL\s*3\z/i) ||
      new_name.match(/\AAGPLv3\z/i) ||
      new_name.match(/\AAGPLv3.0\+\z/i) ||
      new_name.match(/\AAFFERO\s+General\s+Public\s*3\s*\(AGPL\s*3\)\z/i) ||
      new_name.match(/\AAFFERO\s+General\s+Public\s*\(AGPL\s*3\)\z/i) ||
      new_name.match(/\AAFFERO\s+General\s+Public\s*3\z/i)
    end

    def lgpl_20_match name
      new_name = name.gsub(/gnu/i, '').strip
      new_name.match(/\ALGPL\s*2\z/i) ||
      new_name.match(/\ALGPLv2\z/i) ||
      new_name.match(/\ALGPLv2\.0\z/i) ||
      new_name.match(/\ALesser\s+General\s+Public\s+2\s+only\z/i) ||
      new_name.match(/\ALesser\s+General\s+Public\s+2\z/i) || 
      new_name.match(/\ALesser\s+General\s+Public\s*\(LGPL\)\s*2\z/i) || 
      new_name.match(/\ALesser\s+General\s+Public\s*\(LGPL\)\s*2\s+only\z/i) 
    end

    def lgpl_21_match name
      new_name = name.gsub(/gnu/i, '').strip
      new_name.match(/\ALGPL\s*2\.1\z/i) ||
      new_name.match(/\ALGPLv2\.1\z/i) ||
      new_name.match(/\ALesser\s+General\s+Public\s*2\.1\s+only\z/i) ||
      new_name.match(/\ALesser\s+General\s+Public\s*2\.1\z/i) ||
      new_name.match(/\ALesser\s+General\s+Public\s*\(LGPL\)\s*2\.1\z/i) 
    end

    def lgpl_3_match name
      new_name = name.gsub(/gnu/i, '').strip
      new_name.match(/\ALGPLv3\z/i) ||
      new_name.match(/\ALGPL\s*3\z/i) ||
      new_name.match(/\ALESSER\s+GENERAL\s+PUBLIC\s*3\z/i) ||
      new_name.match(/\ALesser\s+General\s+Public\s*3\s*only\z/i) || 
      new_name.match(/\ALibrary\s+or\s+Lesser\s+General\s+Public\s+\(LGPL\)\z/i) || 
      new_name.match(/\ALesser\s+General\s+Public\z/i) || 
      new_name.match(/\ALesser\s+General\s+Public\s+\(LGPL\)\z/i)
    end

    def lgpl_3_or_later_match name
      new_name = name.gsub(/gnu/i, '').strip
      new_name.match(/\ALGPLv3\+\+\z/i) ||
      new_name.match(/\ALGPL\s*3\+\z/i) ||
      new_name.match(/\ALGPL\s*v3\+\z/i) ||
      new_name.match(/\ALesser\s+General\s+Public\s+3\s+or\s+later\s*\z/i)
    end

    def clarified_artistic_match name
      name.match(/\AClarified\s+Artistic\s*\z/i) ||
      name.match(/\AClArtistic\z/i) 
    end

    def artistic_10_match name
      name.match(/\AArtistic\s*\z/i) ||
      name.match(/\AArtistic\s*1\z/i) 
    end
    
    def artistic_10_perl name
      name.match(/\AArtistic\s*Perl\z/i) ||
      name.match(/\AArtistic\s*\(Perl\)\z/i) ||
      name.match(/\AArtistic\s*1\s+Perl\z/i) ||
      name.match(/\AArtistic\s*1\s+\(Perl\)\z/i) 
    end

    def artistic_10_cl8 name
      name.match(/\AArtistic\s+1\s+cl8\z/i) ||
      name.match(/\AArtistic\s+1\s+w\/clause\s+8\z/i)
    end

    def artistic_20_match name
      name.match(/\AArtistic\s*2\z/) ||
      name.match(/\APerl\s*Artistic\s*2\z/) ||
      name.match(/\AArtistic\s*2\z/i)
    end

    def apache_license_10_match name
      new_name = name.gsub(/public/i, '').gsub(/software/i, '').strip
      new_name.match(/ASL\s*1/i) ||
      new_name.match(/ASF\s*1/i) ||
      new_name.match(/Apache\s*1/i) ||
      new_name.match(/Apache\s+ASL\s+1/i) 
    end

    def apache_license_11_match name
      new_name = name.gsub(/public/i, '').gsub(/software/i, '').strip
      new_name.match(/ASL\s+1\.1/xi) ||
      new_name.match(/ASF\s+1\.1/i) ||
      new_name.match(/Apache\s*1\.1/i) ||
      new_name.match(/Apache\s+ASL\s+1\.1/i) 
    end

    def apache_license_20_match name
      new_name = name.gsub(/public/i, '').gsub(/software/i, '').strip
      new_name.match(/ASL\s+2/xi) ||
      new_name.match(/ASF\s*2/i) ||
      new_name.match(/Apache20/i) ||
      new_name.match(/Apache\s*2/i) ||
      new_name.match(/Apache\s+ASL\s*2/i) ||
      new_name.match(/Apache/i) 
    end

    def cddl_match name
      name.match(/\ACDDL\z/i) ||
      name.match(/\ACDDL\s*1\z/i) ||
      name.match(/\ACommon\s+Development\s+and\s+Distribution\s+1\z/i) ||
      name.match(/\ACOMMON\s+DEVELOPMENT\s+AND\s+DISTRIBUTION\s+\(CDDL\)\s+1\z/i) ||
      name.match(/\ACommon\s+Development\s+and\s+Distribution\s+\(CDDL\s*1\)\z/i) ||
      name.match(/\ACommon\s+Development\s+and\s+Distribution\s+\(CDDL\)\s+v1\z/i)
    end

    def cddl_11_match name
      name.match(/\ACDDL\s*1\.1\z/i) ||
      name.match(/\ACommon\s+Development\s+and\s+Distribution\s+1\.1\z/i) ||
      name.match(/\ACOMMON\s+DEVELOPMENT\s+AND\s+DISTRIBUTION\s+\(CDDL\)\s+1\.1\z/i) ||
      name.match(/\ACommon\s+Development\s+and\s+Distribution\s+\(CDDL\s+1\.1\)\z/i) ||
      name.match(/\ACommon\s+Development\s+and\s+Distribution\s+\(CDDL\)\s+v1\.1\z/i)
    end

    def cddl_plus_gpl name
      name.match(/\ACOMMON\s+DEVELOPMENT\s+AND\s+DISTRIBUTION\s+\(CDDL\)\s+plus\s+GPL\z/i) ||
      name.match(/\ACOMMON\s+DEVELOPMENT\s+AND\s+DISTRIBUTION\s+plus\s+GPL\z/i) ||
      name.match(/\ACDDL\s*\+\s*GPL\z/i) || 
      name.match(/\ACDDL\s*plus\s*GPL\z/i)
    end

    def cpl_10_match name
      name.match(/\ACPL1\z/i) ||
      name.match(/\ACPL\s+1\z/i) ||
      name.match(/\ACommon\s+Public\s+v\s+1\z/i) || 
      name.match(/\ACommon\s+Public\s+1\z/i)
    end


    private 

      def do_replacements name 
        tmp_name = name.gsub(/\AThe /i, "").gsub(" - ", " ").gsub(", ", " ").strip
        tmp_name = tmp_name.gsub("-", " ").strip
        tmp_name = tmp_name.gsub(/version/i, " ").strip
        
        tmp_name = tmp_name.gsub(/ v1/i, " 1").strip
        tmp_name = tmp_name.gsub(/1\.0/i, "1").strip

        tmp_name = tmp_name.gsub(/ v2/i, " 2").strip
        tmp_name = tmp_name.gsub(/2\.0/i, "2").strip

        tmp_name = tmp_name.gsub(/ v2\.1/i, " 2.1").strip

        tmp_name = tmp_name.gsub(/ v3/i, " 3").strip
        tmp_name = tmp_name.gsub(/3\.0/i, "3").strip

        tmp_name = tmp_name.gsub(/ v4/i, " 4").strip
        tmp_name = tmp_name.gsub(/4\.0/i, "4").strip
        
        tmp_name = tmp_name.gsub(/Licenses/i, " ").strip 
        tmp_name = tmp_name.gsub(/Licences/i, " ").strip 
        tmp_name = tmp_name.gsub(/Lizenzen/i, " ").strip 
        tmp_name = tmp_name.gsub(/License/i, " ").strip 
        tmp_name = tmp_name.gsub(/Licence/i, " ").strip 
        tmp_name = tmp_name.gsub(/Lizenz/i, " ").strip 

        tmp_name
      end

  end

end
