module VersionEye
  module LicenseNormalizer

    
    A_CDDL_GPL2_W_CPE = 'CDDL+GPLv2 with classpath exception'
    A_CDDL_GPL        = 'CDDL+GPL' # with calsspaht exception 

    A_EDL_1_0 = 'EDL-1.0'
    

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

      spdx = spdx_2_0_map

      spdx_id = has_id_or_fullname?(spdx, name)
      return spdx_id if !spdx_id.to_s.empty? 

      tmp_name = do_replacements(name)

      return A_CDDL_GPL2_W_CPE if cddl_gpl2_w_class_exception( tmp_name )
      return A_CDDL_GPL        if cddl_gpl( tmp_name )

      return 'GPL-2.0-with-classpath-exception' if gpl_20_match_w_cpe( tmp_name )

      return 'AGPL-3.0' if agpl_30_match( tmp_name )
      return 'AGPL-1.0' if agpl_10_match( tmp_name )

      return 'LGPL-2.1+' if lgpl_21_or_later_match( tmp_name )
      return 'LGPL-2.1'  if lgpl_21_match( tmp_name )
      return 'LGPL-2.0+' if lgpl_2_or_later_match( tmp_name )
      return 'LGPL-2.0'  if lgpl_20_match( tmp_name )
      return 'LGPL-3.0+' if lgpl_3_or_later_match( tmp_name )
      return 'LGPL-3.0'  if lgpl_3_match( tmp_name )
      
      return 'GPL-1.0+' if gpl_10_or_later_match( tmp_name )
      return 'GPL-1.0'  if gpl_10_match( tmp_name )
      return 'GPL-2.0+' if gpl_20_or_later_match( tmp_name )
      return 'GPL-2.0'  if gpl_20_match( tmp_name )
      return 'GPL-3.0+' if gpl_30_or_later_match( tmp_name )
      return 'GPL-3.0'  if gpl_30_match( tmp_name )
      return 'GPL'      if gpl_match( tmp_name )

      return 'CC-BY-SA-1.0' if cc_by_sa_10_match( tmp_name )
      return 'CC-BY-SA-2.0' if cc_by_sa_20_match( tmp_name )
      return 'CC-BY-SA-2.5' if cc_by_sa_25_match( tmp_name )
      return 'CC-BY-SA-3.0' if cc_by_sa_30_match( tmp_name )
      return 'CC-BY-SA-4.0' if cc_by_sa_40_match( tmp_name )

      return 'zlib-acknowledgement' if zlib_acknowledgement_match( tmp_name )

      return 'MIT' if mit_match( tmp_name )

      return 'Unlicense' if unlicense_match( tmp_name )

      return 'Ruby' if ruby_match( tmp_name )

      return 'JSON' if json_match( tmp_name )

      return 'CPL-1.0' if cpl_10_match( tmp_name ) # Common Public License 1.0

      return 'MPL-1.1'  if mpl_11_match( tmp_name )
      return 'MPL-1.0'  if mpl_10_match( tmp_name )
      return 'MPL-2.0'  if mpl_20_match( tmp_name )

      return 'CDDL-1.1' if cddl_11_match(  tmp_name )
      return 'CDDL-1.0' if cddl_match( tmp_name )

      return 'Apache-1.1' if apache_license_11_match( tmp_name )
      return 'Apache-1.0' if apache_license_10_match( tmp_name )
      return 'Apache-2.0' if apache_license_20_match( tmp_name )

      return 'EPL-1.0' if eclipse_match( tmp_name ) # Eclipse Public License 1.0
      return A_EDL_1_0 if eclipse_distribution_match( tmp_name ) # Eclipse Distribution License 1.0

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

      nil 
    end


    def link
      if defined?(url) && url && !url.empty?
        return url if url.match(/\Ahttp:\/\//xi) || url.match(/\Ahttps:\/\//xi)
        return "http://#{url}" if url.match(/\Awww\./xi)
      end
      return nil if name.to_s.empty?

      spdx_id = spdx_identifier 
      if spdx_id
        #       https://glassfish.java.net/nonav/public/CDDL+GPL.html - same 
        return 'https://glassfish.java.net/public/CDDL+GPL.html'     if spdx_id.to_s.eql?( A_CDDL_GPL )

        #       https://glassfish.java.net/nonav/public/CDDL+GPL_1_1.html - same 
        return 'https://glassfish.java.net/public/CDDL+GPL_1_1.html' if spdx_id.to_s.eql?( A_CDDL_GPL2_W_CPE ) 

        return 'http://www.eclipse.org/org/documents/edl-v10.php'    if spdx_id.to_s.eql?( A_EDL_1_0 )

        return "http://spdx.org/licenses/#{spdx_id}.html"
      end

      nil
    end


    def equals_id?( license_identifier )
      name_sub = self.name_substitute
      return true if name_sub.eql?( license_identifier )

      if name_sub.eql?('LGPL-2.0+') && (
        license_identifier.eql?('LGPL-2.0') || 
        license_identifier.eql?('LGPL-2.0+') || 
        license_identifier.eql?('LGPL-2.1') || 
        license_identifier.eql?('LGPL-2.1+') || 
        license_identifier.eql?('LGPL-3.0') || 
        license_identifier.eql?('LGPL-3.0+') 
        )
        return true 
      end

      if name_sub.eql?('LGPL-2.1+') && (
        license_identifier.eql?('LGPL-2.1') || 
        license_identifier.eql?('LGPL-2.1+') || 
        license_identifier.eql?('LGPL-3.0') || 
        license_identifier.eql?('LGPL-3.0+') 
        )
        return true 
      end

      if name_sub.eql?('LGPL-3.0+') && (
        license_identifier.eql?('LGPL-3.0') || 
        license_identifier.eql?('LGPL-3.0+') 
        )
        return true 
      end

      if name_sub.eql?('GPL-1.0+') && (
        license_identifier.eql?('GPL-1.0') || 
        license_identifier.eql?('GPL-1.0+') || 
        license_identifier.eql?('GPL-2.0') || 
        license_identifier.eql?('GPL-2.0+') || 
        license_identifier.eql?('GPL-3.0') || 
        license_identifier.eql?('GPL-3.0+') 
        )
        return true 
      end

      if name_sub.eql?('GPL-2.0+') && (
        license_identifier.eql?('GPL-2.0') || 
        license_identifier.eql?('GPL-2.0+') || 
        license_identifier.eql?('GPL-3.0') || 
        license_identifier.eql?('GPL-3.0+') 
        )
        return true 
      end

      if name_sub.eql?('GPL-3.0+') && (
        license_identifier.eql?('GPL-3.0') || 
        license_identifier.eql?('GPL-3.0+') 
        )
        return true 
      end

      false 
    rescue => e 
      log.error e 
      log.error e.backtrace.join("\n")
      false 
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
      name.match(/\AMIT\s*\/\s*X11\s*\z/i) ||
      name.match(/\AMIT\s*\(MIT\)\z/i)
    end

    def unlicense_match name 
      name.match(/\APublic\s*domain\s*\(Unlicense\)\z/i) ||
      name.match(/\AUnlicense\s+\(Public\s+Domain\)\z/i) ||
      name.match(/\A\(Unlicense\)\z/i) || 
      name.match(/\AUnlicensed\z/i) || 
      name.match(/\Aunlicense\.org\z/i) || 
      name.match(/\Ahttp\:\/\/spdx\.org\/licenses\/Unlicense\.html\z/i) || 
      name.match(/\Ahttps\:\/\/spdx\.org\/licenses\/Unlicense\.html\z/i)
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
      tmp_name.match(/\ABSD\z/i) || 
      tmp_name.match(/\ABSD\s*style\z/i) ||
      tmp_name.match(/\ABerkeley\s+Software\s+Distribution\s+\(BSD\)\s*\z/i) ||
      tmp_name.match(/\ABerkeley\s+Software\s+Distribution\s*\z/i) ||
      tmp_name.match(/\ABSD\s*like\z/i) 
    end

    def bsd_2_clause_match name
      tmp_name = name.gsub("-", " ").strip 

      if tmp_name.match(/\ABSD\z/i) && defined?(url) && url.to_s.match(/opensource\.org\/licenses\/BSD\-2\-Clause/i)
        return true 
      end 

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
      new_name.match(/\AGPLv1\z/i) ||
      new_name.match(/\AGPL\s+1\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+1\s+\(GPL\s+1\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+\(GPL\s+1\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+1\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+1\s+only\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+1\z/i)
    end

    def gpl_10_or_later_match name
      new_name = name.gsub(/gnu/i, "").strip 
      
      new_name = name.gsub(/gnu/i, '').strip
      new_name.match(/\AGPL1\+\z/i) ||
      new_name.match(/\AGPLv1\+\z/i) ||
      new_name.match(/\AGPLv1\+\+\z/i) ||
      new_name.match(/\AGPL\s*1\+\z/i) ||
      new_name.match(/\AGPL\s*v1\+\z/i) ||
      new_name.match(/\AGPL\s*v1\s*or\s*later\z/i) ||
      new_name.match(/\AGPL\s*1\s*or\s*later\z/i) ||
      new_name.match(/\APublic\s+1\s+or\s+later\s*\z/i) || 
      new_name.match(/\APublic\s+1\s+or\s+greater\s*\z/i) || 
      new_name.match(/\AGeneral\s+Public\s+1\s+or\s+later\z/i) || 
      new_name.match(/\AGeneral\s+Public\s+1\s+or\s+greater\z/i) || 
      new_name.match(/\AGeneral\s+Public\s+1\+\s+\(GPL\s+1\+\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+\(GPL\s+1\+\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+1\+\z/i)
    end

    def gpl_20_match name
      new_name = name.gsub(/gnu/i, "").strip 
      new_name.match(/\AGPL\s*2\z/i) ||
      new_name.match(/\AGPLv2\+\z/i) ||
      new_name.match(/\AGPLv2\.0\+\z/i) ||
      new_name.match(/\AGPLv2\z/i) ||
      new_name.match(/\AGPL2\+\z/i) ||
      new_name.match(/\AGPL\s*2\+\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+2\s+\(GPL\s+2\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+\(GPL\s+2\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+2\s+only\z/i) || 
      new_name.match(/\AGeneral\s+Public\s+2\z/i)
    end

    def gpl_20_or_later_match name
      new_name = name.gsub(/gnu/i, "").strip 
      
      new_name = name.gsub(/gnu/i, '').strip
      new_name.match(/\AGPL2\+\z/i) ||
      new_name.match(/\AGPLv2\+\z/i) ||
      new_name.match(/\AGPLv2\+\+\z/i) ||
      new_name.match(/\AGPL\s*2\+\z/i) ||
      new_name.match(/\AGPL\s*v2\+\z/i) ||
      new_name.match(/\AGPL\s*v2\s*or\s*later\z/i) ||
      new_name.match(/\AGPL\s*2\s*or\s*later\z/i) ||
      new_name.match(/\APublic\s+2\s+or\s+later\s*\z/i) || 
      new_name.match(/\APublic\s+2\s+or\s+greater\s*\z/i) || 
      new_name.match(/\AGeneral\s+Public\s+2\s+or\s+later\z/i) || 
      new_name.match(/\AGeneral\s+Public\s+2\s+or\s+greater\z/i) || 
      new_name.match(/\AGeneral\s+Public\s+2\+\s+\(GPL\s+2\+\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+\(GPL\s+2\+\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+2\+\z/i)
    end

    def gpl_20_match_w_cpe name
      new_name = name.gsub(/gnu/i, "").strip 
      new_name.match(/\AGeneral\s+Public\s+\(GPL\)\s+2\s+June\s+1991\s+with\s+\"ClassPath\"\s+Exception\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+\(GPL\)\s+2\s+June\s+1991\s+with\s+ClassPath\s+Exception\z/i) ||
      new_name.match(/\AGeneral\s*Public\s*2\.0\s*w\/Classpath\s*exception\z/i) ||
      new_name.match(/\AGeneral\s*Public\s*2\s*w\/Classpath\s*exception\z/i) ||
      new_name.match(/\AGeneral\s*Public\s*2\s*with\s*the\s*Classpath\s*Exception\z/i) ||
      new_name.match(/\AGeneral\s*Public\s*2\s*with\s*Classpath\s*Exception\z/i) ||
      new_name.match(/\AGeneral\s*Public\s*2\s*w\/\s*Classpath\s*Exception\z/i) ||
      new_name.match(/\AGeneral\s*Public\s*2\s*w\s*Classpath\s*Exception\z/i) ||
      new_name.match(/\AGeneral\s*Public\s*2\s*\+\s*Classpath\s*Exception\z/i) ||
      new_name.match(/\AGeneral\s*Public\s*2\s*\+\s*Cpe\z/i) ||
      new_name.match(/\AGPL\s*2\s*w\/\s*CPE\z/i) ||
      new_name.match(/\Agplv2\+ce\z/i) ||
      new_name.match(/\AGPLv2\s*w\/\s*CPE\z/i)
    end

    def gpl_30_match name 
      new_name = name.gsub(/gnu/i, "").strip 

      if name.match(/General\s+Public/i) && defined?(url) && url.to_s.match(/www\.gnu\.org\/licenses\/gpl\.txt/i)
        return true 
      end
      
      new_name.match(/\AGPL3\z/i) ||
      new_name.match(/\AGPL\s*3\z/i) ||
      new_name.match(/\AGPLv3\+\z/i) ||
      new_name.match(/\AGPLv3\.*\+\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+3\s+\(GPL\s+3\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+\(GPL\s+3\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+3\s+only\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+3\z/i)
    end

    def gpl_30_or_later_match name
      new_name = name.gsub(/gnu/i, "").strip 
      
      new_name = name.gsub(/gnu/i, '').strip
      new_name.match(/\AGPL3\+\z/i) ||
      new_name.match(/\AGPLv3\+\z/i) ||
      new_name.match(/\AGPLv3\+\+\z/i) ||
      new_name.match(/\AGPL\s*3\+\z/i) ||
      new_name.match(/\AGPL\s*v3\+\z/i) ||
      new_name.match(/\AGPL\s*v3\s*or\s*later\z/i) ||
      new_name.match(/\AGPL\s*3\s*or\s*later\z/i) ||
      new_name.match(/\APublic\s+3\s+or\s+later\s*\z/i) || 
      new_name.match(/\APublic\s+3\s+or\s+greater\s*\z/i) || 
      new_name.match(/\AGeneral\s+Public\s+3\s+or\s+later\z/i) || 
      new_name.match(/\AGeneral\s+Public\s+3\s+or\s+greater\z/i) || 
      new_name.match(/\AGeneral\s+Public\s+3\+\s+\(GPL\s+3\+\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+\(GPL\s+3\+\)\z/i) ||
      new_name.match(/\AGeneral\s+Public\s+3\+\z/i)
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
      new_name.match(/\ALesser\s+General\s+Public\s+\(LGPL\s+3\)\s*\z/i) || 
      new_name.match(/\ALibrary\s+or\s+Lesser\s+General\s+Public\s+\(LGPL\)\z/i) || 
      new_name.match(/\ALesser\s+General\s+Public\z/i) || 
      new_name.match(/\ALesser\s+General\s+Public\s+\(LGPL\)\z/i) 
    end

    def lgpl_3_or_later_match name
      new_name = name.gsub(/gnu/i, '').strip
      new_name.match(/\ALGPLv3\+\z/i) ||
      new_name.match(/\ALGPLv3\+\+\z/i) ||
      new_name.match(/\ALGPL\s*3\+\z/i) ||
      new_name.match(/\ALGPL\s*v3\+\z/i) ||
      new_name.match(/\ALGPL\s*v3\s*or\s*later\z/i) ||
      new_name.match(/\ALGPL\s*3\s*or\s*later\z/i) ||
      new_name.match(/\ALesser\s+General\s+Public\s+3\s+or\s+later\s*\z/i) || 
      new_name.match(/\ALesser\s+General\s+Public\s+3\s+or\s+greater\s*\z/i) || 
      new_name.match(/\ALibrary\s+General\s+Public\s+3\s+or\s+later\z/i) || 
      new_name.match(/\ALibrary\s+General\s+Public\s+3\s+or\s+greater\z/i)
    end

    def lgpl_2_or_later_match name
      new_name = name.gsub(/gnu/i, '').strip
      new_name.match(/\ALGPLv2\+\z/i) ||
      new_name.match(/\ALGPLv2\+\+\z/i) ||
      new_name.match(/\ALGPL\s*2\+\z/i) ||
      new_name.match(/\ALGPL\s*v2\+\z/i) ||
      new_name.match(/\ALGPL\s*v2\s*or\s*later\z/i) ||
      new_name.match(/\ALGPL\s*2\s*or\s*later\z/i) ||
      new_name.match(/\ALesser\s+General\s+Public\s+2\s+or\s+later\s*\z/i) || 
      new_name.match(/\ALesser\s+General\s+Public\s+2\s+or\s+greater\s*\z/i) || 
      new_name.match(/\ALibrary\s+General\s+Public\s+2\s+or\s+later\z/i) || 
      new_name.match(/\ALibrary\s+General\s+Public\s+2\s+or\s+greater\z/i)
    end

    def lgpl_21_or_later_match name
      new_name = name.gsub(/gnu/i, '').strip
      new_name.match(/\ALGPLv2\.1\+\z/i) ||
      new_name.match(/\ALGPLv2\.1\+\+\z/i) ||
      new_name.match(/\ALGPL\s*2\.1\+\z/i) ||
      new_name.match(/\ALGPL\s*v2\.1\+\z/i) ||
      new_name.match(/\ALGPL\s*v2\.1\s*or\s*later\z/i) ||
      new_name.match(/\ALGPL\s*2\.1\s*or\s*later\z/i) ||
      new_name.match(/\ALesser\s+General\s+Public\s+2\.1\s+or\s+later\s*\z/i) || 
      new_name.match(/\ALesser\s+General\s+Public\s+2\.1\s+or\s+greater\s*\z/i) || 
      new_name.match(/\ALibrary\s+General\s+Public\s+2\.1\s+or\s+later\z/i) || 
      new_name.match(/\ALibrary\s+General\s+Public\s+2\.1\s+or\s+greater\z/i)
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
      new_name.match(/ASLv1/i) ||
      new_name.match(/ASF\s*1/i) ||
      new_name.match(/Apache\s*1/i) ||
      new_name.match(/Apache\s+ASL\s+1/i) 
    end

    def apache_license_11_match name
      new_name = name.gsub(/public/i, '').gsub(/software/i, '').strip
      new_name.match(/ASL\s+1\.1/xi) ||
      new_name.match(/ASLv1\.1/xi) ||
      new_name.match(/ASF\s+1\.1/i) ||
      new_name.match(/ASFv1\.1/i) ||
      new_name.match(/Apache\s*1\.1/i) ||
      new_name.match(/Apache\s+ASL\s+1\.1/i) 
    end

    def apache_license_20_match name
      new_name = name.gsub(/public/i, '').gsub(/software/i, '').strip
      new_name.match(/ASL\s+2/xi) ||
      new_name.match(/ASLv2/xi) ||
      new_name.match(/ASF\s*2/i) ||
      new_name.match(/ASFv2/i) ||
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

    # It is with classpath exception as well. 
    def cddl_gpl name
      if defined?(url) && (
         url.to_s.match(/glassfish\.java\.net\/nonav\/public\/CDDL\+GPL\.html\z/i) || 
         url.to_s.match(/glassfish\.java\.net\/public\/CDDL\+GPL\.html\z/i) 
         )
         return true 
      end
      name.match(/\ACOMMON\s+DEVELOPMENT\s+AND\s+DISTRIBUTION\s+\(CDDL\)\s+plus\s+GPL\z/i) ||
      name.match(/\ACOMMON\s+DEVELOPMENT\s+AND\s+DISTRIBUTION\s+plus\s+GPL\z/i) ||
      name.match(/\ACDDL\s*\+\s*GPL\z/i) || 
      name.match(/\ACDDL\s*plus\s*GPL\z/i)
    end

    def cddl_gpl2_w_class_exception name
      if defined?(url) && (
         url.to_s.match(/glassfish\.java\.net\/public\/CDDL\+GPL_1_1\.html\z/i) || 
         url.to_s.match(/glassfish\.java\.net\/nonav\/public\/CDDL\+GPL_1_1\.html\z/i)
         )
         return true 
      end
      name.match(/\ACOMMON\s+DEVELOPMENT\s+AND\s+DISTRIBUTION\s+\(CDDL\)\s+plus\s+GPL\s*2\s*with\s*classpath\s*exception\z/i) ||
      name.match(/\ACOMMON\s+DEVELOPMENT\s+AND\s+DISTRIBUTION\s+plus\s+GPL[v]*\s*2\s*with\s*classpath\s*exception\z/i) ||
      name.match(/\ACDDL\s*plus\s*GPL\s*2\s*with\s*classpath\s*exception\s*\z/i) || 
      name.match(/\ACDDL\s*\+\s*GPLv2\s*with\s*classpath\s*exception\s*\z/i) ||
      name.match(/\ACDDL\s*\+\s*GPL\s*2\s*with\s*classpath\s*exception\s*\z/i) || 
      name.match(/\ACDDL\s+or\s+GPLv2\s+with\s+exceptions\z/i) || 
      name.match(/\ACDDL\s+or\s+GPL\s*2\s+with\s+exceptions\z/i) || 
      name.match(/\ADual\s+consisting\s+of\s+the\s+CDDL\s+1\.1\s+and\s+GPL\s+2\z/i) ||
      name.match(/\ACDDL\+GPL_1_1\z/i) ||
      name.match(/\ACDDL\s*\+\s*GPL\s+1\.1\z/i) ||
      name.match(/\ACDDL\s+1.1\s+\/\s+GPL\s+2\s+dual\z/i) ||
      name.match(/\ACDDL\/GPLv2\+CE\z/i) ||
      name.match(/\ACDDL\s*\+\s*GPL2\s*w\/\s*CPE\s*\z/i)
    end

    
    def cpl_10_match name
      name.match(/\ACPL1\z/i) ||
      name.match(/\ACPL\s+1\z/i) ||
      name.match(/\ACommon\s+Public\s+v\s+1\z/i) || 
      name.match(/\ACommon\s+Public\s+1\z/i)
    end


    def zlib_acknowledgement_match name
      name.match(/\Azlib\/libpng\s*License\s*with\s*Acknowledgement\s*\z/i) ||
      name.match(/\Azlib\/libpng\s*with\s*Acknowledgement\s*\z/i) ||
      name.match(/\Azlib-acknowledgement\z/i)
    end
  

    private 

      def has_id_or_fullname?(map, name) 
        map.keys.each do |key|
          return key if key.upcase.eql?(name.upcase)
          return key if map[key][:fullname].upcase.eql?(name.upcase)
        end
        nil 
      end
      
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
        
        if tmp_name.match(/unlicense/i) == nil
          tmp_name = tmp_name.gsub(/Licenses/i, " ").strip 
          tmp_name = tmp_name.gsub(/Licences/i, " ").strip 
          tmp_name = tmp_name.gsub(/Lizenzen/i, " ").strip 
          tmp_name = tmp_name.gsub(/Licenzen/i, " ").strip 
          tmp_name = tmp_name.gsub(/License/i, " ").strip 
          tmp_name = tmp_name.gsub(/Licence/i, " ").strip 
          tmp_name = tmp_name.gsub(/Lizenz/i, " ").strip 
        end

        tmp_name
      end

      def spdx_2_0_map
        @@map ||= init_spdx_2_0_map
      end

      def init_spdx_2_0_map
        # This is autogenerated by the SPDX license crawler. 
        map = {}
        map['Glide'] = {:fullname => '3dfx Glide License', :osi_approved => false}
        map['Abstyles'] = {:fullname => 'Abstyles License', :osi_approved => false}
        map['AFL-1.1'] = {:fullname => 'Academic Free License v1.1', :osi_approved => true}
        map['AFL-1.2'] = {:fullname => 'Academic Free License v1.2', :osi_approved => true}
        map['AFL-2.0'] = {:fullname => 'Academic Free License v2.0', :osi_approved => true}
        map['AFL-2.1'] = {:fullname => 'Academic Free License v2.1', :osi_approved => true}
        map['AFL-3.0'] = {:fullname => 'Academic Free License v3.0', :osi_approved => true}
        map['AMPAS'] = {:fullname => 'Academy of Motion Picture Arts and Sciences BSD', :osi_approved => false}
        map['APL-1.0'] = {:fullname => 'Adaptive Public License 1.0', :osi_approved => true}
        map['Adobe-Glyph'] = {:fullname => 'Adobe Glyph List License', :osi_approved => false}
        map['APAFML'] = {:fullname => 'Adobe Postscript AFM License', :osi_approved => false}
        map['Adobe-2006'] = {:fullname => 'Adobe Systems Incorporated Source Code License Agreement', :osi_approved => false}
        map['AGPL-1.0'] = {:fullname => 'Affero General Public License v1.0', :osi_approved => false}
        map['Afmparse'] = {:fullname => 'Afmparse License', :osi_approved => false}
        map['Aladdin'] = {:fullname => 'Aladdin Free Public License', :osi_approved => false}
        map['ADSL'] = {:fullname => 'Amazon Digital Services License', :osi_approved => false}
        map['AMDPLPA'] = {:fullname => 'AMD\'s plpa_map.c License', :osi_approved => false}
        map['ANTLR-PD'] = {:fullname => 'ANTLR Software Rights Notice', :osi_approved => false}
        map['Apache-1.0'] = {:fullname => 'Apache License 1.0', :osi_approved => false}
        map['Apache-1.1'] = {:fullname => 'Apache License 1.1', :osi_approved => true}
        map['Apache-2.0'] = {:fullname => 'Apache License 2.0', :osi_approved => true}
        map['AML'] = {:fullname => 'Apple MIT License', :osi_approved => false}
        map['APSL-1.0'] = {:fullname => 'Apple Public Source License 1.0', :osi_approved => true}
        map['APSL-1.1'] = {:fullname => 'Apple Public Source License 1.1', :osi_approved => true}
        map['APSL-1.2'] = {:fullname => 'Apple Public Source License 1.2', :osi_approved => true}
        map['APSL-2.0'] = {:fullname => 'Apple Public Source License 2.0', :osi_approved => true}
        map['Artistic-1.0'] = {:fullname => 'Artistic License 1.0', :osi_approved => true}
        map['Artistic-1.0-Perl'] = {:fullname => 'Artistic License 1.0 (Perl)', :osi_approved => true}
        map['Artistic-1.0-cl8'] = {:fullname => 'Artistic License 1.0 w/clause 8', :osi_approved => true}
        map['Artistic-2.0'] = {:fullname => 'Artistic License 2.0', :osi_approved => true}
        map['AAL'] = {:fullname => 'Attribution Assurance License', :osi_approved => true}
        map['Bahyph'] = {:fullname => 'Bahyph License', :osi_approved => false}
        map['Barr'] = {:fullname => 'Barr License', :osi_approved => false}
        map['Beerware'] = {:fullname => 'Beerware License', :osi_approved => false}
        map['BitTorrent-1.0'] = {:fullname => 'BitTorrent Open Source License v1.0', :osi_approved => false}
        map['BitTorrent-1.1'] = {:fullname => 'BitTorrent Open Source License v1.1', :osi_approved => false}
        map['BSL-1.0'] = {:fullname => 'Boost Software License 1.0', :osi_approved => true}
        map['Borceux'] = {:fullname => 'Borceux license', :osi_approved => false}
        map['BSD-2-Clause'] = {:fullname => 'BSD 2-clause \"Simplified\" License', :osi_approved => true}
        map['BSD-2-Clause-FreeBSD'] = {:fullname => 'BSD 2-clause FreeBSD License', :osi_approved => false}
        map['BSD-2-Clause-NetBSD'] = {:fullname => 'BSD 2-clause NetBSD License', :osi_approved => false}
        map['BSD-3-Clause'] = {:fullname => 'BSD 3-clause \"New\" or \"Revised\" License', :osi_approved => true}
        map['BSD-3-Clause-Clear'] = {:fullname => 'BSD 3-clause Clear License', :osi_approved => false}
        map['BSD-4-Clause'] = {:fullname => 'BSD 4-clause \"Original\" or \"Old\" License', :osi_approved => false}
        map['BSD-Protection'] = {:fullname => 'BSD Protection License', :osi_approved => false}
        map['BSD-3-Clause-Attribution'] = {:fullname => 'BSD with attribution', :osi_approved => false}
        map['BSD-4-Clause-UC'] = {:fullname => 'BSD-4-Clause (University of California-Specific)', :osi_approved => false}
        map['bzip2-1.0.5'] = {:fullname => 'bzip2 and libbzip2 License v1.0.5', :osi_approved => false}
        map['bzip2-1.0.6'] = {:fullname => 'bzip2 and libbzip2 License v1.0.6', :osi_approved => false}
        map['Caldera'] = {:fullname => 'Caldera License', :osi_approved => false}
        map['CECILL-1.0'] = {:fullname => 'CeCILL Free Software License Agreement v1.0', :osi_approved => false}
        map['CECILL-1.1'] = {:fullname => 'CeCILL Free Software License Agreement v1.1', :osi_approved => false}
        map['CECILL-2.0'] = {:fullname => 'CeCILL Free Software License Agreement v2.0', :osi_approved => false}
        map['CECILL-B'] = {:fullname => 'CeCILL-B Free Software License Agreement', :osi_approved => false}
        map['CECILL-C'] = {:fullname => 'CeCILL-C Free Software License Agreement', :osi_approved => false}
        map['ClArtistic'] = {:fullname => 'Clarified Artistic License', :osi_approved => false}
        map['MIT-CMU'] = {:fullname => 'CMU License', :osi_approved => false}
        map['CNRI-Python'] = {:fullname => 'CNRI Python License', :osi_approved => true}
        map['CNRI-Python-GPL-Compatible'] = {:fullname => 'CNRI Python Open Source GPL Compatible License Agreement', :osi_approved => false}
        map['CPOL-1.02'] = {:fullname => 'Code Project Open License 1.02', :osi_approved => false}
        map['CDDL-1.0'] = {:fullname => 'Common Development and Distribution License 1.0', :osi_approved => true}
        map['CDDL-1.1'] = {:fullname => 'Common Development and Distribution License 1.1', :osi_approved => false}
        map['CPAL-1.0'] = {:fullname => 'Common Public Attribution License 1.0', :osi_approved => true}
        map['CPL-1.0'] = {:fullname => 'Common Public License 1.0', :osi_approved => true}
        map['CATOSL-1.1'] = {:fullname => 'Computer Associates Trusted Open Source License 1.1', :osi_approved => true}
        map['Condor-1.1'] = {:fullname => 'Condor Public License v1.1', :osi_approved => false}
        map['CC-BY-1.0'] = {:fullname => 'Creative Commons Attribution 1.0', :osi_approved => false}
        map['CC-BY-2.0'] = {:fullname => 'Creative Commons Attribution 2.0', :osi_approved => false}
        map['CC-BY-2.5'] = {:fullname => 'Creative Commons Attribution 2.5', :osi_approved => false}
        map['CC-BY-3.0'] = {:fullname => 'Creative Commons Attribution 3.0', :osi_approved => false}
        map['CC-BY-4.0'] = {:fullname => 'Creative Commons Attribution 4.0', :osi_approved => false}
        map['CC-BY-ND-1.0'] = {:fullname => 'Creative Commons Attribution No Derivatives 1.0', :osi_approved => false}
        map['CC-BY-ND-2.0'] = {:fullname => 'Creative Commons Attribution No Derivatives 2.0', :osi_approved => false}
        map['CC-BY-ND-2.5'] = {:fullname => 'Creative Commons Attribution No Derivatives 2.5', :osi_approved => false}
        map['CC-BY-ND-3.0'] = {:fullname => 'Creative Commons Attribution No Derivatives 3.0', :osi_approved => false}
        map['CC-BY-ND-4.0'] = {:fullname => 'Creative Commons Attribution No Derivatives 4.0', :osi_approved => false}
        map['CC-BY-NC-1.0'] = {:fullname => 'Creative Commons Attribution Non Commercial 1.0', :osi_approved => false}
        map['CC-BY-NC-2.0'] = {:fullname => 'Creative Commons Attribution Non Commercial 2.0', :osi_approved => false}
        map['CC-BY-NC-2.5'] = {:fullname => 'Creative Commons Attribution Non Commercial 2.5', :osi_approved => false}
        map['CC-BY-NC-3.0'] = {:fullname => 'Creative Commons Attribution Non Commercial 3.0', :osi_approved => false}
        map['CC-BY-NC-4.0'] = {:fullname => 'Creative Commons Attribution Non Commercial 4.0', :osi_approved => false}
        map['CC-BY-NC-ND-1.0'] = {:fullname => 'Creative Commons Attribution Non Commercial No Derivatives 1.0', :osi_approved => false}
        map['CC-BY-NC-ND-2.0'] = {:fullname => 'Creative Commons Attribution Non Commercial No Derivatives 2.0', :osi_approved => false}
        map['CC-BY-NC-ND-2.5'] = {:fullname => 'Creative Commons Attribution Non Commercial No Derivatives 2.5', :osi_approved => false}
        map['CC-BY-NC-ND-3.0'] = {:fullname => 'Creative Commons Attribution Non Commercial No Derivatives 3.0', :osi_approved => false}
        map['CC-BY-NC-ND-4.0'] = {:fullname => 'Creative Commons Attribution Non Commercial No Derivatives 4.0', :osi_approved => false}
        map['CC-BY-NC-SA-1.0'] = {:fullname => 'Creative Commons Attribution Non Commercial Share Alike 1.0', :osi_approved => false}
        map['CC-BY-NC-SA-2.0'] = {:fullname => 'Creative Commons Attribution Non Commercial Share Alike 2.0', :osi_approved => false}
        map['CC-BY-NC-SA-2.5'] = {:fullname => 'Creative Commons Attribution Non Commercial Share Alike 2.5', :osi_approved => false}
        map['CC-BY-NC-SA-3.0'] = {:fullname => 'Creative Commons Attribution Non Commercial Share Alike 3.0', :osi_approved => false}
        map['CC-BY-NC-SA-4.0'] = {:fullname => 'Creative Commons Attribution Non Commercial Share Alike 4.0', :osi_approved => false}
        map['CC-BY-SA-1.0'] = {:fullname => 'Creative Commons Attribution Share Alike 1.0', :osi_approved => false}
        map['CC-BY-SA-2.0'] = {:fullname => 'Creative Commons Attribution Share Alike 2.0', :osi_approved => false}
        map['CC-BY-SA-2.5'] = {:fullname => 'Creative Commons Attribution Share Alike 2.5', :osi_approved => false}
        map['CC-BY-SA-3.0'] = {:fullname => 'Creative Commons Attribution Share Alike 3.0', :osi_approved => false}
        map['CC-BY-SA-4.0'] = {:fullname => 'Creative Commons Attribution Share Alike 4.0', :osi_approved => false}
        map['CC0-1.0'] = {:fullname => 'Creative Commons Zero v1.0 Universal', :osi_approved => false}
        map['Crossword'] = {:fullname => 'Crossword License', :osi_approved => false}
        map['CUA-OPL-1.0'] = {:fullname => 'CUA Office Public License v1.0', :osi_approved => true}
        map['Cube'] = {:fullname => 'Cube License', :osi_approved => false}
        map['D-FSL-1.0'] = {:fullname => 'Deutsche Freie Software Lizenz', :osi_approved => false}
        map['diffmark'] = {:fullname => 'diffmark license', :osi_approved => false}
        map['WTFPL'] = {:fullname => 'Do What The F*ck You Want To Public License', :osi_approved => false}
        map['DOC'] = {:fullname => 'DOC License', :osi_approved => false}
        map['Dotseqn'] = {:fullname => 'Dotseqn License', :osi_approved => false}
        map['DSDP'] = {:fullname => 'DSDP License', :osi_approved => false}
        map['dvipdfm'] = {:fullname => 'dvipdfm License', :osi_approved => false}
        map['EPL-1.0'] = {:fullname => 'Eclipse Public License 1.0', :osi_approved => true}
        map['ECL-1.0'] = {:fullname => 'Educational Community License v1.0', :osi_approved => true}
        map['ECL-2.0'] = {:fullname => 'Educational Community License v2.0', :osi_approved => true}
        map['eGenix'] = {:fullname => 'eGenix.com Public License 1.1.0', :osi_approved => false}
        map['EFL-1.0'] = {:fullname => 'Eiffel Forum License v1.0', :osi_approved => true}
        map['EFL-2.0'] = {:fullname => 'Eiffel Forum License v2.0', :osi_approved => true}
        map['MIT-advertising'] = {:fullname => 'Enlightenment License (e16)', :osi_approved => false}
        map['MIT-enna'] = {:fullname => 'enna License', :osi_approved => false}
        map['Entessa'] = {:fullname => 'Entessa Public License v1.0', :osi_approved => true}
        map['ErlPL-1.1'] = {:fullname => 'Erlang Public License v1.1', :osi_approved => false}
        map['EUDatagrid'] = {:fullname => 'EU DataGrid Software License', :osi_approved => true}
        map['EUPL-1.0'] = {:fullname => 'European Union Public License 1.0', :osi_approved => false}
        map['EUPL-1.1'] = {:fullname => 'European Union Public License 1.1', :osi_approved => true}
        map['Eurosym'] = {:fullname => 'Eurosym License', :osi_approved => false}
        map['Fair'] = {:fullname => 'Fair License', :osi_approved => true}
        map['MIT-feh'] = {:fullname => 'feh License', :osi_approved => false}
        map['Frameworx-1.0'] = {:fullname => 'Frameworx Open License 1.0', :osi_approved => true}
        map['FreeImage'] = {:fullname => 'FreeImage Public License v1.0', :osi_approved => false}
        map['FTL'] = {:fullname => 'Freetype Project License', :osi_approved => false}
        map['FSFUL'] = {:fullname => 'FSF Unlimited License', :osi_approved => false}
        map['FSFULLR'] = {:fullname => 'FSF Unlimited License (with License Retention)', :osi_approved => false}
        map['Giftware'] = {:fullname => 'Giftware License', :osi_approved => false}
        map['GL2PS'] = {:fullname => 'GL2PS License', :osi_approved => false}
        map['Glulxe'] = {:fullname => 'Glulxe License', :osi_approved => false}
        map['AGPL-3.0'] = {:fullname => 'GNU Affero General Public License v3.0', :osi_approved => true}
        map['GFDL-1.1'] = {:fullname => 'GNU Free Documentation License v1.1', :osi_approved => false}
        map['GFDL-1.2'] = {:fullname => 'GNU Free Documentation License v1.2', :osi_approved => false}
        map['GFDL-1.3'] = {:fullname => 'GNU Free Documentation License v1.3', :osi_approved => false}
        map['GPL-1.0'] = {:fullname => 'GNU General Public License v1.0 only', :osi_approved => false}
        map['GPL-2.0'] = {:fullname => 'GNU General Public License v2.0 only', :osi_approved => true}
        map['GPL-3.0'] = {:fullname => 'GNU General Public License v3.0 only', :osi_approved => true}
        map['LGPL-2.1'] = {:fullname => 'GNU Lesser General Public License v2.1 only', :osi_approved => true}
        map['LGPL-3.0'] = {:fullname => 'GNU Lesser General Public License v3.0 only', :osi_approved => true}
        map['LGPL-2.0'] = {:fullname => 'GNU Library General Public License v2 only', :osi_approved => true}
        map['gnuplot'] = {:fullname => 'gnuplot License', :osi_approved => false}
        map['gSOAP-1.3b'] = {:fullname => 'gSOAP Public License v1.3b', :osi_approved => false}
        map['HaskellReport'] = {:fullname => 'Haskell Language Report License', :osi_approved => false}
        map['HPND'] = {:fullname => 'Historic Permission Notice and Disclaimer', :osi_approved => true}
        map['IBM-pibs'] = {:fullname => 'IBM PowerPC Initialization and Boot Software', :osi_approved => false}
        map['IPL-1.0'] = {:fullname => 'IBM Public License v1.0', :osi_approved => true}
        map['ImageMagick'] = {:fullname => 'ImageMagick License', :osi_approved => false}
        map['iMatix'] = {:fullname => 'iMatix Standard Function Library Agreement', :osi_approved => false}
        map['Imlib2'] = {:fullname => 'Imlib2 License', :osi_approved => false}
        map['IJG'] = {:fullname => 'Independent JPEG Group License', :osi_approved => false}
        map['Intel-ACPI'] = {:fullname => 'Intel ACPI Software License Agreement', :osi_approved => false}
        map['Intel'] = {:fullname => 'Intel Open Source License', :osi_approved => true}
        map['IPA'] = {:fullname => 'IPA Font License', :osi_approved => true}
        map['ISC'] = {:fullname => 'ISC License', :osi_approved => true}
        map['JasPer-2.0'] = {:fullname => 'JasPer License', :osi_approved => false}
        map['JSON'] = {:fullname => 'JSON License', :osi_approved => false}
        map['LPPL-1.3a'] = {:fullname => 'LaTeX Project Public License 1.3a', :osi_approved => false}
        map['LPPL-1.0'] = {:fullname => 'LaTeX Project Public License v1.0', :osi_approved => false}
        map['LPPL-1.1'] = {:fullname => 'LaTeX Project Public License v1.1', :osi_approved => false}
        map['LPPL-1.2'] = {:fullname => 'LaTeX Project Public License v1.2', :osi_approved => false}
        map['LPPL-1.3c'] = {:fullname => 'LaTeX Project Public License v1.3c', :osi_approved => true}
        map['Latex2e'] = {:fullname => 'Latex2e License', :osi_approved => false}
        map['BSD-3-Clause-LBNL'] = {:fullname => 'Lawrence Berkeley National Labs BSD variant license', :osi_approved => false}
        map['Leptonica'] = {:fullname => 'Leptonica License', :osi_approved => false}
        map['Libpng'] = {:fullname => 'libpng License', :osi_approved => false}
        map['libtiff'] = {:fullname => 'libtiff License', :osi_approved => false}
        map['LPL-1.02'] = {:fullname => 'Lucent Public License v1.02', :osi_approved => true}
        map['LPL-1.0'] = {:fullname => 'Lucent Public License Version 1.0', :osi_approved => true}
        map['MakeIndex'] = {:fullname => 'MakeIndex License', :osi_approved => false}
        map['MTLL'] = {:fullname => 'Matrix Template Library License', :osi_approved => false}
        map['MS-PL'] = {:fullname => 'Microsoft Public License', :osi_approved => true}
        map['MS-RL'] = {:fullname => 'Microsoft Reciprocal License', :osi_approved => true}
        map['MirOS'] = {:fullname => 'MirOS Licence', :osi_approved => true}
        map['MITNFA'] = {:fullname => 'MIT +no-false-attribs license', :osi_approved => false}
        map['MIT'] = {:fullname => 'MIT License', :osi_approved => true}
        map['Motosoto'] = {:fullname => 'Motosoto License', :osi_approved => true}
        map['MPL-1.0'] = {:fullname => 'Mozilla Public License 1.0', :osi_approved => true}
        map['MPL-1.1'] = {:fullname => 'Mozilla Public License 1.1', :osi_approved => true}
        map['MPL-2.0'] = {:fullname => 'Mozilla Public License 2.0', :osi_approved => true}
        map['MPL-2.0-no-copyleft-exception'] = {:fullname => 'Mozilla Public License 2.0 (no copyleft exception)', :osi_approved => true}
        map['mpich2'] = {:fullname => 'mpich2 License', :osi_approved => false}
        map['Multics'] = {:fullname => 'Multics License', :osi_approved => true}
        map['Mup'] = {:fullname => 'Mup License', :osi_approved => false}
        map['NASA-1.3'] = {:fullname => 'NASA Open Source Agreement 1.3', :osi_approved => true}
        map['Naumen'] = {:fullname => 'Naumen Public License', :osi_approved => true}
        map['NBPL-1.0'] = {:fullname => 'Net Boolean Public License v1', :osi_approved => false}
        map['NetCDF'] = {:fullname => 'NetCDF license', :osi_approved => false}
        map['NGPL'] = {:fullname => 'Nethack General Public License', :osi_approved => true}
        map['NOSL'] = {:fullname => 'Netizen Open Source License', :osi_approved => false}
        map['NPL-1.0'] = {:fullname => 'Netscape Public License v1.0', :osi_approved => false}
        map['NPL-1.1'] = {:fullname => 'Netscape Public License v1.1', :osi_approved => false}
        map['Newsletr'] = {:fullname => 'Newsletr License', :osi_approved => false}
        map['NLPL'] = {:fullname => 'No Limit Public License', :osi_approved => false}
        map['Nokia'] = {:fullname => 'Nokia Open Source License', :osi_approved => true}
        map['NPOSL-3.0'] = {:fullname => 'Non-Profit Open Software License 3.0', :osi_approved => true}
        map['Noweb'] = {:fullname => 'Noweb License', :osi_approved => false}
        map['NRL'] = {:fullname => 'NRL License', :osi_approved => false}
        map['NTP'] = {:fullname => 'NTP License', :osi_approved => true}
        map['Nunit'] = {:fullname => 'Nunit License', :osi_approved => false}
        map['OCLC-2.0'] = {:fullname => 'OCLC Research Public License 2.0', :osi_approved => true}
        map['ODbL-1.0'] = {:fullname => 'ODC Open Database License v1.0', :osi_approved => false}
        map['PDDL-1.0'] = {:fullname => 'ODC Public Domain Dedication & License 1.0', :osi_approved => false}
        map['OGTSL'] = {:fullname => 'Open Group Test Suite License', :osi_approved => true}
        map['OLDAP-2.2.2'] = {:fullname => 'Open LDAP Public License  2.2.2', :osi_approved => false}
        map['OLDAP-1.1'] = {:fullname => 'Open LDAP Public License v1.1', :osi_approved => false}
        map['OLDAP-1.2'] = {:fullname => 'Open LDAP Public License v1.2', :osi_approved => false}
        map['OLDAP-1.3'] = {:fullname => 'Open LDAP Public License v1.3', :osi_approved => false}
        map['OLDAP-1.4'] = {:fullname => 'Open LDAP Public License v1.4', :osi_approved => false}
        map['OLDAP-2.0'] = {:fullname => 'Open LDAP Public License v2.0 (or possibly 2.0A and 2.0B)', :osi_approved => false}
        map['OLDAP-2.0.1'] = {:fullname => 'Open LDAP Public License v2.0.1', :osi_approved => false}
        map['OLDAP-2.1'] = {:fullname => 'Open LDAP Public License v2.1', :osi_approved => false}
        map['OLDAP-2.2'] = {:fullname => 'Open LDAP Public License v2.2', :osi_approved => false}
        map['OLDAP-2.2.1'] = {:fullname => 'Open LDAP Public License v2.2.1', :osi_approved => false}
        map['OLDAP-2.3'] = {:fullname => 'Open LDAP Public License v2.3', :osi_approved => false}
        map['OLDAP-2.4'] = {:fullname => 'Open LDAP Public License v2.4', :osi_approved => false}
        map['OLDAP-2.5'] = {:fullname => 'Open LDAP Public License v2.5', :osi_approved => false}
        map['OLDAP-2.6'] = {:fullname => 'Open LDAP Public License v2.6', :osi_approved => false}
        map['OLDAP-2.7'] = {:fullname => 'Open LDAP Public License v2.7', :osi_approved => false}
        map['OLDAP-2.8'] = {:fullname => 'Open LDAP Public License v2.8', :osi_approved => false}
        map['OML'] = {:fullname => 'Open Market License', :osi_approved => false}
        map['OPL-1.0'] = {:fullname => 'Open Public License v1.0', :osi_approved => false}
        map['OSL-1.0'] = {:fullname => 'Open Software License 1.0', :osi_approved => true}
        map['OSL-1.1'] = {:fullname => 'Open Software License 1.1', :osi_approved => false}
        map['OSL-2.0'] = {:fullname => 'Open Software License 2.0', :osi_approved => true}
        map['OSL-2.1'] = {:fullname => 'Open Software License 2.1', :osi_approved => true}
        map['OSL-3.0'] = {:fullname => 'Open Software License 3.0', :osi_approved => true}
        map['OpenSSL'] = {:fullname => 'OpenSSL License', :osi_approved => false}
        map['PHP-3.0'] = {:fullname => 'PHP License v3.0', :osi_approved => true}
        map['PHP-3.01'] = {:fullname => 'PHP License v3.01', :osi_approved => false}
        map['Plexus'] = {:fullname => 'Plexus Classworlds License', :osi_approved => false}
        map['PostgreSQL'] = {:fullname => 'PostgreSQL License', :osi_approved => true}
        map['psfrag'] = {:fullname => 'psfrag License', :osi_approved => false}
        map['psutils'] = {:fullname => 'psutils License', :osi_approved => false}
        map['Python-2.0'] = {:fullname => 'Python License 2.0', :osi_approved => true}
        map['QPL-1.0'] = {:fullname => 'Q Public License 1.0', :osi_approved => true}
        map['Qhull'] = {:fullname => 'Qhull License', :osi_approved => false}
        map['Rdisc'] = {:fullname => 'Rdisc License', :osi_approved => false}
        map['RPSL-1.0'] = {:fullname => 'RealNetworks Public Source License v1.0', :osi_approved => true}
        map['RPL-1.1'] = {:fullname => 'Reciprocal Public License 1.1', :osi_approved => true}
        map['RPL-1.5'] = {:fullname => 'Reciprocal Public License 1.5', :osi_approved => true}
        map['RHeCos-1.1'] = {:fullname => 'Red Hat eCos Public License v1.1', :osi_approved => false}
        map['RSCPL'] = {:fullname => 'Ricoh Source Code Public License', :osi_approved => true}
        map['Ruby'] = {:fullname => 'Ruby License', :osi_approved => false}
        map['SAX-PD'] = {:fullname => 'Sax Public Domain Notice', :osi_approved => false}
        map['Saxpath'] = {:fullname => 'Saxpath License', :osi_approved => false}
        map['SCEA'] = {:fullname => 'SCEA Shared Source License', :osi_approved => false}
        map['SWL'] = {:fullname => 'Scheme Widget Library (SWL) Software License Agreement', :osi_approved => false}
        map['SGI-B-1.0'] = {:fullname => 'SGI Free Software License B v1.0', :osi_approved => false}
        map['SGI-B-1.1'] = {:fullname => 'SGI Free Software License B v1.1', :osi_approved => false}
        map['SGI-B-2.0'] = {:fullname => 'SGI Free Software License B v2.0', :osi_approved => false}
        map['OFL-1.0'] = {:fullname => 'SIL Open Font License 1.0', :osi_approved => false}
        map['OFL-1.1'] = {:fullname => 'SIL Open Font License 1.1', :osi_approved => true}
        map['SimPL-2.0'] = {:fullname => 'Simple Public License 2.0', :osi_approved => true}
        map['Sleepycat'] = {:fullname => 'Sleepycat License', :osi_approved => true}
        map['SNIA'] = {:fullname => 'SNIA Public License 1.1', :osi_approved => false}
        map['SMLNJ'] = {:fullname => 'Standard ML of New Jersey License', :osi_approved => false}
        map['SugarCRM-1.1.3'] = {:fullname => 'SugarCRM Public License v1.1.3', :osi_approved => false}
        map['SISSL'] = {:fullname => 'Sun Industry Standards Source License v1.1', :osi_approved => true}
        map['SISSL-1.2'] = {:fullname => 'Sun Industry Standards Source License v1.2', :osi_approved => false}
        map['SPL-1.0'] = {:fullname => 'Sun Public License v1.0', :osi_approved => true}
        map['Watcom-1.0'] = {:fullname => 'Sybase Open Watcom Public License 1.0', :osi_approved => true}
        map['TCL'] = {:fullname => 'TCL/TK License', :osi_approved => false}
        map['Unlicense'] = {:fullname => 'The Unlicense', :osi_approved => false}
        map['TMate'] = {:fullname => 'TMate Open Source License', :osi_approved => false}
        map['TORQUE-1.1'] = {:fullname => 'TORQUE v2.5+ Software License v1.1', :osi_approved => false}
        map['TOSL'] = {:fullname => 'Trusster Open Source License', :osi_approved => false}
        map['Unicode-TOU'] = {:fullname => 'Unicode Terms of Use', :osi_approved => false}
        map['NCSA'] = {:fullname => 'University of Illinois/NCSA Open Source License', :osi_approved => true}
        map['Vim'] = {:fullname => 'Vim License', :osi_approved => false}
        map['VOSTROM'] = {:fullname => 'VOSTROM Public License for Open Source', :osi_approved => false}
        map['VSL-1.0'] = {:fullname => 'Vovida Software License v1.0', :osi_approved => true}
        map['W3C'] = {:fullname => 'W3C Software Notice and License (2002-12-31)', :osi_approved => true}
        map['W3C-19980720'] = {:fullname => 'W3C Software Notice and License (1998-07-20)', :osi_approved => false}
        map['Wsuipa'] = {:fullname => 'Wsuipa License', :osi_approved => false}
        map['Xnet'] = {:fullname => 'X.Net License', :osi_approved => true}
        map['X11'] = {:fullname => 'X11 License', :osi_approved => false}
        map['Xerox'] = {:fullname => 'Xerox License', :osi_approved => false}
        map['XFree86-1.1'] = {:fullname => 'XFree86 License 1.1', :osi_approved => false}
        map['xinetd'] = {:fullname => 'xinetd License', :osi_approved => false}
        map['xpp'] = {:fullname => 'XPP License', :osi_approved => false}
        map['XSkat'] = {:fullname => 'XSkat License', :osi_approved => false}
        map['YPL-1.0'] = {:fullname => 'Yahoo! Public License v1.0', :osi_approved => false}
        map['YPL-1.1'] = {:fullname => 'Yahoo! Public License v1.1', :osi_approved => false}
        map['Zed'] = {:fullname => 'Zed License', :osi_approved => false}
        map['Zend-2.0'] = {:fullname => 'Zend License v2.0', :osi_approved => false}
        map['Zimbra-1.3'] = {:fullname => 'Zimbra Public License v1.3', :osi_approved => false}
        map['Zimbra-1.4'] = {:fullname => 'Zimbra Public License v1.4', :osi_approved => false}
        map['Zlib'] = {:fullname => 'zlib License', :osi_approved => true}
        map['zlib-acknowledgement'] = {:fullname => 'zlib/libpng License with Acknowledgement', :osi_approved => false}
        map['ZPL-1.1'] = {:fullname => 'Zope Public License 1.1', :osi_approved => false}
        map['ZPL-2.0'] = {:fullname => 'Zope Public License 2.0', :osi_approved => true}
        map['ZPL-2.1'] = {:fullname => 'Zope Public License 2.1', :osi_approved => false}
        map['ICU'] = {:fullname => 'ICU License', :osi_approved => false}

        map['eCos-2.0']                         = {:fullname => 'eCos license version 2.0', :osi_approved => false}
        map['GPL-1.0+']                         = {:fullname => 'GNU General Public License v1.0 or later', :osi_approved => false}
        map['GPL-2.0+']                         = {:fullname => 'GNU General Public License v2.0 or later', :osi_approved => false}
        map['GPL-2.0-with-autoconf-exception']  = {:fullname => 'GNU General Public License v2.0 w/Autoconf exception', :osi_approved => false}
        map['GPL-2.0-with-bison-exception']     = {:fullname => 'GNU General Public License v2.0 w/Bison exception', :osi_approved => false}
        map['GPL-2.0-with-classpath-exception'] = {:fullname => 'GNU General Public License v2.0 w/Classpath exception', :osi_approved => false}
        map['GPL-2.0-with-font-exception']      = {:fullname => 'GNU General Public License v2.0 w/Font exception', :osi_approved => false}
        map['GPL-2.0-with-GCC-exception']       = {:fullname => 'GNU General Public License v2.0 w/GCC Runtime Library exception', :osi_approved => false}
        map['GPL-3.0+']                         = {:fullname => 'GNU General Public License v3.0 or later', :osi_approved => false}
        map['GPL-3.0-with-autoconf-exception']  = {:fullname => 'GNU General Public License v3.0 w/Autoconf exception', :osi_approved => false}
        map['GPL-3.0-with-GCC-exception']       = {:fullname => 'GNU General Public License v3.0 w/GCC Runtime Library exception', :osi_approved => false}
        map['LGPL-2.1+']                        = {:fullname => 'GNU Lesser General Public License v2.1 or later', :osi_approved => false}
        map['LGPL-3.0+']                        = {:fullname => 'GNU Lesser General Public License v3.0 or later', :osi_approved => false}
        map['LGPL-2.0+']                        = {:fullname => 'GNU Library General Public License v2 or later', :osi_approved => false}
        map['StandardML-NJ']                    = {:fullname => 'Standard ML of New Jersey License', :osi_approved => false}
        map['WXwindows']                        = {:fullname => 'wxWindows Library License', :osi_approved => false}

        map
      end

  end

end
