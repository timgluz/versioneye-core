class BadgeService < Versioneye::Service


  A_TTL_24H = 86400 # 24 hours
  A_TTL_12H = 43200 # 12 hours
  A_TTL_6H  = 21600 # 6 hours


  def self.badge_for( key )
    badge = cache.get key
    return badge if badge

    badge = Badge.where(:key => key).first
    if badge
      DependencyBadgeProducer.new(key) if badge.updated_at < 1.day.ago
    else
      badge = update( key )
    end
    badge
  rescue => e
    logger.error e.message
    Badge.new({:status => Badge::A_UP_TO_DATE})
  end


  def self.update( key )
    if key.to_s.split(":::").size > 1
      update_product_badge( key )
    else
      update_project_badge( key )
    end
  end


  def self.update_project_badge( key )
    badge = Badge.find_or_create_by( key: key )

    sp1        = key.split("__")
    project_id = sp1[0]
    style      = sp1[1]

    project = Project.find_by_id project_id.to_s
    if project.nil?
      badge.status       = Badge::A_UNKNOWN
      badge.badge_source = Badge::A_SOURCE_PROJECT
      badge.badge_type   = Badge::A_TYPE_DEPENDENCY
      badge.badge_style  = style
      badge.svg          = fetch_svg( badge )
      badge.save
      cache.set( key, badge, A_TTL_24H )
      return badge
    end

    outdated = ProjectService.outdated?( project )
    insecure = ProjectService.insecure?( project )

    badge.status      = Badge::A_OUT_OF_DATE if outdated == true
    badge.status      = Badge::A_UP_TO_DATE  if outdated == false
    badge.status      = Badge::A_UPDATE      if insecure == true
    badge_source      = Badge::A_SOURCE_PROJECT
    badge.badge_type  = Badge::A_TYPE_DEPENDENCY
    badge.badge_style = style
    badge.svg         = fetch_svg( badge )
    badge.save
    cache.set( key, badge, A_TTL_6H )
    badge
  end


  def self.update_product_badge( key )
    badge = Badge.find_or_create_by( key: key )

    sp1    = key.split("__")
    splits = sp1[0].split(":::")
    language = splits[0]
    prod_key = splits[1]
    version  = splits[2]
    style    = sp1[1]

    product = Product.fetch_product language, prod_key
    if product.nil?
      badge.status       = Badge::A_UNKNOWN
      badge.badge_source = Badge::A_SOURCE_PRODUCT
      badge.badge_type   = Badge::A_TYPE_DEPENDENCY
      badge.badge_style  = style
      badge.svg          = fetch_svg( badge )
      badge.save
      cache.set( key, badge, A_TTL_24H )
      return badge
    end

    product.version = version if version
    dependencies    = product.dependencies
    if dependencies.nil? || dependencies.empty?
      badge.status       = Badge::A_NONE
      badge.badge_source = Badge::A_SOURCE_PRODUCT
      badge.badge_type   = Badge::A_TYPE_DEPENDENCY
      badge.badge_style  = style
      badge.svg          = fetch_svg( badge )
      badge.save
      cache.set( key, badge, A_TTL_24H )
      return badge
    end

    outdated = DependencyService.dependencies_outdated?( dependencies, false )
    badge.status       = Badge::A_OUT_OF_DATE if outdated == true
    badge.status       = Badge::A_UP_TO_DATE  if outdated == false
    badge.badge_source = Badge::A_SOURCE_PRODUCT
    badge.badge_type   = Badge::A_TYPE_DEPENDENCY
    badge.badge_style  = style
    badge.svg          = fetch_svg( badge )
    badge.save
    cache.set( key, badge, A_TTL_12H )
    badge
  end


  def self.fetch_svg badge
    return Badge::A_UPTODATE_SVG_FLAT if badge.status.eql?(Badge::A_UP_TO_DATE) && (badge.badge_style.to_s.eql?('flat') || badge.badge_style.to_s.eql?('flat-square'))
    return Badge::A_UPTODATE_SVG      if badge.status.eql?(Badge::A_UP_TO_DATE)

    return Badge::A_OUTOFDATE_SVG_FLAT if badge.status.eql?(Badge::A_OUT_OF_DATE) && (badge.badge_style.to_s.eql?('flat') || badge.badge_style.to_s.eql?('flat-square'))
    return Badge::A_OUTOFDATE_SVG      if badge.status.eql?(Badge::A_OUT_OF_DATE)

    return Badge::A_UPDATE_SVG_FLAT if badge.status.eql?(Badge::A_UPDATE) && (badge.badge_style.to_s.eql?('flat') || badge.badge_style.to_s.eql?('flat-square'))
    return Badge::A_UPDATE_SVG      if badge.status.eql?(Badge::A_UPDATE)

    return Badge::A_NONE_SVG_FLAT if badge.status.eql?(Badge::A_NONE) && (badge.badge_style.to_s.eql?('flat') || badge.badge_style.to_s.eql?('flat-square'))
    return Badge::A_NONE_SVG      if badge.status.eql?(Badge::A_NONE)

    return Badge::A_UNKNOWN_SVG   if badge.status.eql?(Badge::A_UNKNOWN)
  end


end
