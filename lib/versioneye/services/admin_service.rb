class AdminService < Versioneye::Service

  def self.create_default_admin
    admin = User.where({:username => 'admin'}).first
    return true if admin

    admin = User.new({:username => 'admin', :fullname => 'admin',
      :email => 'admin@admin.com', :password => 'admin', :terms => true,
      :datenerhebung => true })
    admin[:admin] = true
    admin.save
  end

end
