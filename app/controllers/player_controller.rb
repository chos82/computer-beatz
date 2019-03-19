class PlayerController < ApplicationController
  
  def single
    @releases = Release.find(:all, :conditions => ['id = ?', params[:id]])
  end
  
  def project
    @releases = Release.find(:all, :conditions => ['project_id = ?', params[:id]], :order => ['created_at DESC'])
  end
  
  def all
    @releases = Release.find(:all, :order => ['created_at DESC'])
  end
  
end
