class LicenseFactory

  def self.create_new product, name
    license = License.new({:language => product.language, :prod_key => product.prod_key,
      :version => product.version, :name => name })
    license.save
    license
  end

end
