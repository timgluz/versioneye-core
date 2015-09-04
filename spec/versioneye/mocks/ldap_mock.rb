class LdapMock

  attr_accessor :host, :port, :base, :filter, :password, :username, :email

  def bind_as( hash )
    return nil if !hash[:password].eql?(self.password)

    [{:uid => [self.username], :mail => [self.email]}]
  end

end