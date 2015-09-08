class LdapMock

  attr_accessor :host, :port, :base, :filter, :password, :username, :email

  def bind
    true
  end

  def search( hash )
    [{:uid => [self.username], :mail => [self.email]}]
  end

end