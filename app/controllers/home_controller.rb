class HomeController < ApplicationController
  
  def index
    @newsletter = Newsletter.find(:all, :order => ['created_at DESC'], :limit => 5)
    @music = Music.find(:all, :order => ['created_at DESC'], :limit => 5)
    @gn = NewsMessage.find(:all, :order => ['created_at DESC'], :limit => 5, :include => [:topic])
    @releases = Release.find(:all, :order => ['created_at DESC'], :conditions => ["state = 'released'"], :limit => 3, :include => [:project])
    @people = User.find(:all, :order => ['created_at DESC'], :conditions => ['enabled = true'], :limit => 5)
  end
 
end
