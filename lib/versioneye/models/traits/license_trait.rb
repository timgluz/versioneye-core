module VersionEye
  module LicenseTrait

    def name_substitute
      return 'unknown' if name.to_s.empty?
      return 'MIT' if mit_match( name )
      return 'BSD' if bsd_match( name )
      return 'Ruby' if ruby_match( name )
      return 'CDDL' if cddl_match( name )
      return 'GPL-2.0' if gpl_20_match( name )

      return 'LGPL-3.0' if lgpl_3_match( name )
      return 'LGPL-3.0+' if lgpl_3_or_later_match( name )

      return 'Apache License 1.0' if apache_license_10_match( name )
      return 'Apache License 1.1' if apache_license_11_match( name )
      return 'Apache License 2.0' if apache_license_20_match( name )
      return 'Apache License' if apache_license_match( name )

      return 'Eclipse Public License 1.0' if eclipse_match( name )

      return 'Artistic License 1.0' if artistic_10_match( name )
      return 'Artistic License 2.0' if artistic_20_match( name )
      name
    end

    def ruby_match name
      name.match(/\ARuby\z/i) ||
      name.match(/\ARuby 1\.8\z/i) ||
      name.match(/\ARuby License\z/i)
    end

    def mit_match name
      name.match(/\AMIT\z/i) ||
      name.match(/\AMIT License\z/i) ||
      name.match(/\AThe MIT License\z/i)
    end

    def eclipse_match name
      name.match(/\AEclipse\z/i) ||
      name.match(/\AEclipse License\z/i) ||
      name.match(/\AEclipse Public License\z/i) ||
      name.match(/\AEclipse Public License 1\.0\z/i) ||
      name.match(/\AEclipse Public License v1\.0\z/i) ||
      name.match(/\AEclipse Public License \- v 1\.0\z/i) ||
      name.match(/\AEclipse Public License Version 1\.0\z/i) ||
      name.match(/\AEclipse Public License, Version 1\.0\z/i)
    end

    def bsd_match name
      name.match(/\ABSD\z/) ||
      name.match(/\ABSD License\z/i) ||
      name.match(/\AThe BSD License\z/i)
    end

    def gpl_match name
      name.match(/\AGPL\z/i)
    end

    def gpl_20_match name
      name.match(/\AGPL 2\z/i) ||
      name.match(/\AGPL\-2\z/i) ||
      name.match(/\AGPLv2\+\z/i) ||
      name.match(/\AGPL 2\.0\z/i) ||
      name.match(/\AGPL\-2\.0\z/i)
    end

    def lgpl_3_match name
      name.match(/\ALGPL 3\z/i) ||
      name.match(/\ALGPLv3\z/i) ||
      name.match(/\ALGPL\-3\z/i) ||
      name.match(/\AGNU Lesser General Public License v3\.0 only\z/i)
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
      name.match(/\AArtistic License 2.0\z/i)
    end

    def apache_license_match name
      name.match(/\AApache\z/i) ||
      name.match(/\AApache License\z/i) ||
      name.match(/\AApache Software License\z/i) ||
      name.match(/\AApache Software Licenses\z/i)
    end

    def apache_license_10_match name
      name.match(/\AApache 1\z/i) ||
      name.match(/\AApache\-1\z/i) ||
      name.match(/\AApache 1\.0\z/i) ||
      name.match(/\AApache\-1\.0\z/i) ||
      name.match(/\AApache License 1\z/i) ||
      name.match(/\AApache License 1\.0\z/i) ||
      name.match(/\AApache License Version 1\.0\z/i) ||
      name.match(/\AApache License\, Version 1\.0\z/i) ||
      name.match(/\AApache Software License - Version 1\.0\z/i) ||
      name.match(/\AThe Apache Software License\, Version 1\.0\z/i)
    end

    def apache_license_11_match name
      name.match(/\AApache 1\.1\z/i) ||
      name.match(/\AApache\-1\.1\z/i) ||
      name.match(/\AApache License 1\.1\z/i) ||
      name.match(/\AApache License Version 1\.1\z/i) ||
      name.match(/\AApache License\, Version 1\.1\z/i) ||
      name.match(/\AApache Software License - Version 1\.1\z/i) ||
      name.match(/\AThe Apache Software License\, Version 1\.1\z/i)
    end

    def apache_license_20_match name
      name.match(/\AApache 2\z/i) ||
      name.match(/\AApache\-2\z/i) ||
      name.match(/\AApache 2\.0\z/i) ||
      name.match(/\AApache\-2\.0\z/i) ||
      name.match(/\AApache License 2\z/i) ||
      name.match(/\AApache License 2\.0\z/i) ||
      name.match(/\AApache License Version 2\.0\z/i) ||
      name.match(/\AApache License\, Version 2\.0\z/i) ||
      name.match(/\AApache Software License - Version 2\.0\z/i) ||
      name.match(/\AThe Apache Software License\, Version 2\.0\z/i)
    end

    def cddl_match name
      name.match(/\ACDDL\z/i) ||
      name.match(/\ACOMMON DEVELOPMENT AND DISTRIBUTION LICENSE (CDDL) Version 1.0\z/i) ||
      name.match(/\ACommon Development and Distribution License (CDDL) v1.0\z/i)
    end

  end

end
