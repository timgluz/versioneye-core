class AuthorService < Versioneye::Service

  def self.update_authors language
    Developer.where(:language => language).any_of({:to_author => false}, {:to_author => nil}).each do |dev|
      dev_to_author dev
    end
  end


  def self.dev_to_author dev
    author = fetch_author dev
    if author.nil?
      p " -- ERROR for #{dev.email}"
      return
    end

    author.update_from dev

    product = dev.product
    id = nil
    id = product.ids if product
    author.add_product id, dev.language, dev.prod_key
    if author.save
      dev.update_attributes :to_author => true
      p author.name_id
    else
      p "ERROR - #{author.errors.full_messages.to_sentence}"
    end
  end


  def self.update_maintainers
    User.all.each do |user|
      update_maintainer user
    end
  end

  def self.update_maintainer user
    return if user.deleted_user == true

    authors = Author.where(:emails => user.email)
    return if authors.empty?

    authors.each do |author|
      author.products.each do |product|
        if user.add_maintainer(product)
          p "#{user.username} can edit #{product}"
        end
      end
    end
    user.save
  end


  def self.invite_users_to_edit
    User.all.each do |user|
      invite_user_to_edit user
    end
  end

  def self.invite_user_to_edit user
    return if user.deleted_user == true

    authors = Author.where(:emails => user.email)
    return if authors.empty?

    p "invite user #{user.username} to edit"
    UserMailer.invited_user_author( user, authors ).deliver_now
  end


  private


    def self.fetch_author dev
      if dev.name.to_s.empty?
        author = Author.where( :email => dev.email ).first
        author = Author.where( :emails => dev.email ).first if author.nil?
        return nil
      end
      name_id = Author.encode_name( dev.name )
      author = Author.where( :name_id => name_id ).first
      author = Author.new({:name_id => name_id}) if author.nil?
      author
    end


end
