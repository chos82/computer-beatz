xml.instruct!
xml.urlset :xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9' do
  @projects.each do |page|
    xml.url do
      xml.loc project_url(page)
      xml.lastmod page.updated_at.xmlschema
    end
  end
  @releases.each do |page|
    xml.url do
      xml.loc release_url(page)
      xml.lastmod page.updated_at.xmlschema
    end
  end
  @music.each do |page|
    xml.url do
      xml.loc "http://" + SITE_URL + url_for( :controller => page.type.to_s.downcase.pluralize, :action => :show, :id => page )
      xml.lastmod page.updated_at.xmlschema
    end
  end
  @groups.each do |page|
    xml.url do
      xml.loc group_url(page)
      xml.lastmod page.updated_at.xmlschema
    end
  end
  @topics.each do |page|
    xml.url do
      xml.loc group_topic_url(page.group_id, page)
      xml.lastmod page.updated_at.xmlschema
    end
  end
  @newsletter.each do |page|
    xml.url do
      xml.loc newsletter_url(page)
      xml.lastmod page.updated_at.xmlschema
    end
  end
end