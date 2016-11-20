class AuthorService < Versioneye::Service


  def self.update_authors_all
    Product::A_LANGS_LANGUAGE_PAGE.each do |lang|
      self.update_authors lang
    end
  end


  def self.update_authors language
    Developer.where(:language => language).any_of({:to_author => false}, {:to_author => nil}).each do |dev|
      dev_to_author dev
    end
  end


  def self.dev_to_author dev
    product = dev.product
    if product.nil?
      log.error "ERROR - developer #{dev.ids} #{dev.name} without product for #{dev.language}/#{dev.prod_key}!"
      return nil
    end

    author = find_or_create_author_by dev
    if author.nil?
      log.error " -- ERROR - could not fetch author for developer.id #{dev.ids} with email #{dev.email}"
      return nil
    end

    author.update_from dev
    author.add_product product.ids, dev.language, dev.prod_key
    if author.save
      dev.update_attributes :to_author => true
      log.info "dev to author - #{author.name_id}"
      return author
    else
      log.error "ERROR - #{author.errors.full_messages.to_sentence}"
      return nil
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


  def self.find_or_create_author_by dev
    return nil if dev_to_ignore?( dev )

    if dev.dev_identifier.to_s.empty?
      author = Author.where( :email => dev.email ).first
      author = Author.where( :emails => dev.email ).first if author.nil?
      return author if author
    end
    name_id = Author.encode_name( dev.dev_identifier )
    author  = Author.where( :name_id => name_id ).first
    if author.nil?
      author = Author.new({:name_id => name_id, :name => dev.dev_identifier})
      log.info "New Author #{name_id}"
    end
    author
  end


  def self.dev_to_ignore? dev
    dev && dev.dev_identifier.to_s.eql?('Matej Kieres')
  end


  def self.all_authors_paged
    count = Author.count()
    page = 100
    iterations = count / page
    iterations += 1
    (0..iterations).each do |i|
      skip = i * page
      authors = Author.all().skip(skip).limit(page)

      yield authors

      co = i * page
      log_msg = "all_authors_paged iteration: #{i} - authors processed: #{co}"
      p log_msg
      log.info log_msg
    end
  rescue => e
    log.error e.message
    log.error e.backtrace.join("\n")
  end


end
