class License < Versioneye::Model

  include Mongoid::Document
  include Mongoid::Timestamps

  require 'versioneye/models/traits/license_trait'
  include VersionEye::LicenseTrait

  # This license belongs to the product with this attributes
  field :language     , type: String
  field :prod_key     , type: String
  field :version      , type: String

  field :name           , type: String # For example MIT
  field :url            , type: String # URL to the license text
  field :comments       , type: String # Maven specific
  field :distributions  , type: String # Maven specific
  field :spdx_identifier, type: String # For example AGPL-1.0. See http://spdx.org/licenses/
  field :source         , type: String # Where it was crawled

  # TODO This is causing a too large index. For Python some names are containnign the license text. This need to be fixest! See -> License.where(:name => /\n/).count
  # index({ language: 1, prod_key: 1, version: 1, name: 1 }, { name: "language_prod_key_version_name_index", background: true })
  index({ language: 1, prod_key: 1, version: 1 },          { name: "language_prod_key_version_index"     , background: true })
  index({ language: 1, prod_key: 1},                       { name: "language_prod_key_index"             , background: true })

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

  # Returns the licenses with nil version!
  def self.for_product_global product
    return License.where(:language => product.language, :prod_key => product.prod_key, :version => nil)
  end

  def self.find_or_create language, prod_key, version, name, url = nil, comments = nil, distributions = nil
    license = License.where(:language => language, :prod_key => prod_key, :version => version, :name => name).first
    return license if license

    license = License.new({ :language => language, :prod_key => prod_key, :version => version, :name => name, :url => url, :comments => comments, :distributions => distributions })
    license.save
    license
  end

  def link
    if url && !url.empty?
      return url if url.match(/\Ahttp:\/\//xi) || url.match(/\Ahttps:\/\//xi)
      return "http://#{url}"
    end
    return nil if name.to_s.empty?

    tmp_name = name.gsub(/The /i, "").gsub(" - ", " ").gsub(", ", " ").gsub("Licence", "License").strip

    return 'http://mit-license.org/' if mit_match( tmp_name )

    return 'http://www.json.org/license.html' if json_match( tmp_name )

    return 'http://www.ruby-lang.org/en/about/license.txt' if ruby_match( tmp_name )

    return 'http://www.apache.org/licenses/LICENSE-1.0.txt' if apache_license_10_match( tmp_name )
    return 'http://www.apache.org/licenses/LICENSE-1.1.txt' if apache_license_11_match( tmp_name )
    return 'http://www.apache.org/licenses/LICENSE-2.0.txt' if apache_license_20_match( tmp_name )

    return 'http://opensource.org/licenses/MPL-1.0' if mpl_10_match( tmp_name )
    return 'http://opensource.org/licenses/MPL-1.1' if mpl_11_match( tmp_name )
    return 'http://opensource.org/licenses/MPL-2.0' if mpl_20_match( tmp_name )

    return 'http://opensource.org/licenses/CPL-1.0' if cpl_10_match( tmp_name )

    return 'http://www.eclipse.org/legal/epl-v10.html' if eclipse_match( tmp_name )
    return 'http://www.eclipse.org/org/documents/edl-v10.php' if eclipse_distribution_match( tmp_name )

    return 'http://opensource.org/licenses/BSD-3-Clause' if bsd_3_clause_match( tmp_name )
    return 'http://opensource.org/licenses/bsd-license' if new_bsd_match( tmp_name )
    return 'http://www.linfo.org/bsdlicense.html' if bsd_style_match( tmp_name )
    return 'http://www.linfo.org/bsdlicense.html' if bsd_match( tmp_name )

    return 'http://www.gnu.org/copyleft/gpl.html'                             if gpl_match( tmp_name )
    return 'http://www.gnu.org/licenses/old-licenses/gpl-1.0-standalone.html' if gpl_10_match( tmp_name )
    return 'http://opensource.org/licenses/gpl-2.0'                           if gpl_20_match( tmp_name )
    return 'http://opensource.org/licenses/GPL-3.0'                           if gpl_30_match( tmp_name )

    return 'http://spdx.org/licenses/LGPL-2.0' if lgpl_20_match( tmp_name )
    return 'http://opensource.org/licenses/LGPL-2.1' if lgpl_21_match( tmp_name )
    return 'http://opensource.org/licenses/LGPL-3.0' if lgpl_3_match( tmp_name )
    return 'http://spdx.org/licenses/LGPL-3.0+' if lgpl_3_or_later_match( tmp_name )

    return 'http://opensource.org/licenses/artistic-license-1.0' if artistic_10_match( tmp_name )
    return 'http://opensource.org/licenses/artistic-license-2.0' if artistic_20_match( tmp_name )

    return 'http://spdx.org/licenses/CDDL-1.0.html' if cddl_match( tmp_name )
    return 'http://spdx.org/licenses/CDDL-1.1.html' if cddl_11_match( tmp_name )
    
    return 'https://glassfish.java.net/nonav/public/CDDL+GPL.html' if cddl_plus_gpl( tmp_name )

    nil
  end

  def to_s
    "[License for (#{language}/#{prod_key}/#{version}) : #{name}]"
  end

end
