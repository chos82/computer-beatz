class FeedController < ApplicationController
  
  def news
    releases = Release.find(:all, :conditions => ["state = 'released'"], :order => 'created_at DESC', :limit => 5)
    messages = NewsMessage.find(:all, :order => 'updated_at DESC', :limit => 15)
    music = Music.find(:all, :order => "created_at DESC", :limit => 15)
    groups = Group.find(:all, :order => 'created_at DESC', :limit => 5)
    newsletter = Newsletter.find(:all, :order => 'created_at DESC', :limit => 5)
    @latest = releases + newsletter + groups + music + messages
    @latest.sort!{|x,y|
      x.created_at <=> y.created_at
    }
    @latest.reverse!
    @date = @latest.first.created_at# || @latest.first.updated_at
    headers["Content-Type"] = "application/rss+xml"
    render :layout => false
  end
  
  def podcast
    @releases = Release.find(:all, :conditions => ["state = 'released'"], :order => 'created_at DESC', :limit => 20)
    headers["Content-Type"] = "application/rss+xml"
    render :layout => false
  end
  
end
