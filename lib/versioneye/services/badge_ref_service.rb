class BadgeRefService < BadgeService


  def self.update( key )
    update_product_badge( key )
  end


  def self.update_product_badge( key )
    badge = Badge.find_or_create_by( key: key )

    splits = key.split(":::")
    language = splits[0]
    prod_key = splits[1]
    version  = splits[2]

    reference = ReferenceService.find_by language, prod_key

    if reference && reference.ref_count > 0
      badge.status       = reference.ref_count
      badge.badge_source = Badge::A_SOURCE_PRODUCT
      badge.badge_type   = Badge::A_TYPE_REFERENCE
      badge.svg          = fetch_svg( badge )
      badge.save
      cache.set( key, badge, A_TTL_24H )
      return badge
    end

    badge.status       = Badge::A_REF_0
    badge.svg          = Badge::A_REF_0_SVG
    badge.badge_source = Badge::A_SOURCE_PRODUCT
    badge.badge_type   = Badge::A_TYPE_REFERENCE
    badge.save
    cache.set( key, badge, A_TTL_24H )
    return badge
  end


  def self.fetch_svg badge
    return Badge::A_REF_0_SVG     if badge.status.eql?(Badge::A_REF_0_SVG)
    return Badge::A_REF_TEMPLATE_SVG.gsub("TMP", badge.status)
  end


end
