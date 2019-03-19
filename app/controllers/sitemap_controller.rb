class SitemapController < ApplicationController
  
  def sitemap
    @music = Music.find_for_sitemap 43000
    @groups = Group.find_for_sitemap 1000
    @topics = Topic.find_for_sitemap 5000
    @projects = Project.find_for_sitemap 100
    @releases = Release.find_for_sitemap 500
    @newsletter = Newsletter.find_for_sitemap 400
    last_mod = []
    last_mod << @music[0] if @music[0]
    last_mod << @groups[0] if @groups[0]
    last_mod << @topics[0] if @topics[0]
    last_mod << @projects[0] if @projects[0]
    last_mod << @releases[0] if @releases[0]
    last_mod.sort!{|x,y|
      x.updated_at <=> y.updated_at
    }
    headers["Last-Modified"] = last_mod[0].updated_at.httpdate if last_mod
    render :layout => false 
  end

end
