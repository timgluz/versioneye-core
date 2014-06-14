class License < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  # This license belongs to the product with this attributes
  field :language     , type: String
  field :prod_key     , type: String
  field :version      , type: String

  field :name         , type: String # For example MIT
  field :url          , type: String # URL to the license text
  field :comments     , type: String # Maven specific
  field :distributions, type: String # Maven specific

  validates_presence_of :language, :message => 'language is mandatory!'
  validates_presence_of :prod_key, :message => 'prod_key is mandatory!'
  validates_presence_of :name, :message => 'name is mandatory!'

  def product
    Product.fetch_product(self.language, self.prod_key)
  end

  def self.for_product( product, ignore_version = false )
    if ignore_version
      return License.where(:language => product.language, :prod_key => product.prod_key)
    else
      return License.where(:language => product.language, :prod_key => product.prod_key, :version => product.version)
    end
  end

  def self.find_or_create language, prod_key, version, name, url = nil, comments = nil, distributions = nil
    license = License.where(:language => language, :prod_key => prod_key, :version => version, :name => name).first
    return license if license

    license = License.new({ :language => language, :prod_key => prod_key, :version => version, :name => name, :url => url, :comments => comments, :distributions => distributions })
    license.save
    license
  end

  def link
    return url if url && !url.empty?
    return 'http://www.linfo.org/bsdlicense.html' if bsd_match( name )
    return 'http://choosealicense.com/licenses/mit/' if mit_match( name )
    return 'http://www.ruby-lang.org/en/about/license.txt' if ruby_match( name )
    return 'http://www.apache.org/licenses/LICENSE-2.0.txt' if apache_license_2_match( name )
    return 'http://choosealicense.com/licenses/eclipse/' if eclipse_match( name )
    return 'http://opensource.org/licenses/gpl-2.0.php' if gpl_20_match( name )
    return 'http://opensource.org/licenses/artistic-license-1.0' if artistic_10_match( name )
    return 'http://opensource.org/licenses/artistic-license-2.0' if artistic_20_match( name )
    nil
  end

  def name_substitute
    return 'unknown' if name.to_s.empty?
    return 'MIT' if mit_match( name )
    return 'BSD' if bsd_match( name )
    return 'Ruby' if ruby_match( name )
    return 'GPL-2.0' if gpl_20_match( name )
    return 'Apache License, Version 2.0' if apache_license_2_match( name )
    return 'Apache License' if apache_license_match( name )
    return 'Eclipse Public License v1.0' if eclipse_match( name )
    return 'Artistic License 1.0' if artistic_10_match( name )
    return 'Artistic License 2.0' if artistic_20_match( name )
    name
  end

  def to_s
    "[License for (#{language}/#{prod_key}/#{version}) : #{name}]"
  end

  private

    def ruby_match name
      name.match(/\ARuby\z/i) || name.match(/\ARuby License\z/)
    end

    def mit_match name
      name.match(/\AMIT\z/i) || name.match(/\AThe MIT License\z/) || name.match(/\AMIT License\z/)
    end

    def eclipse_match name
      name.match(/\AEclipse\z/i) || name.match(/\AEclipse Public License v1\.0\z/) || name.match(/\AEclipse License\z/) || name.match(/\AEclipse Public License\z/) || name.match(/\AEclipse Public License \- v 1\.0\z/)
    end

    def bsd_match name
      name.match(/\ABSD License\z/i) || name.match(/\ABSD\z/)
    end

    def gpl_20_match name
      name.match(/\AGPL\-2\z/i) || name.match(/\AGPL\-2\.0\z/i)  || name.match(/\AGPL 2\.0\z/i) || name.match(/\AGPL 2\z/i)
    end

    def artistic_10_match name
      name.match(/\AArtistic License 1\.0\z/i) || name.match(/\AArtistic License\z/) || name.match(/\AArtistic\-1\.0\z/) || name.match(/\AArtistic 1\.0\z/)
    end

    def artistic_20_match name
      name.match(/\AArtistic License 2.0\z/i) || name.match(/\AArtistic 2.0\z/)
    end

    def apache_license_match name
      name.match(/\AApache License\z/i) || name.match(/\AApache Software Licenses\z/i) || name.match(/\AApache Software License\z/i)
    end

    def apache_license_2_match name
      name.match(/\AApache License\, Version 2\.0\z/i) ||
      name.match(/\AApache License Version 2\.0\z/i) ||
      name.match(/\AThe Apache Software License\, Version 2\.0\z/i) ||
      name.match(/\AApache 2\z/i) ||
      name.match(/\AApache\-2\z/i) ||
      name.match(/\AApache\-2\.0\z/i) ||
      name.match(/\AApache 2\.0\z/i) ||
      name.match(/\AApache License 2\.0\z/i) ||
      name.match(/\AApache Software License - Version 2\.0\z/i)
    end

end
