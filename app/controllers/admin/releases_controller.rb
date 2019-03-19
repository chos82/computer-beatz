class Admin::ReleasesController < ApplicationController
  layout 'admin'
  
  before_filter :check_administrator_role
  
  def index
    @releases = Release.find(:all, :conditions => ["state = 'uploaded'"])
  end
  
  def publish
    @release = Release.find(params[:id])
    @release.state = 'released'
    
    if @release.save
      flash[:notice] = 'Release was successfully published.'
      recipients = User.find(:all, :include => [:project_memberships], :conditions => ['project_memberships.project_id = ?', @release.project_id])
      for recipient in recipients do
        ReleaseMailer.deliver_released_notification(@release, recipient)
      end
    else 
      flash[:error] = 'An error occured. Model didn`t get saved. Try again!'
    end
      redirect_to admin_releases_path
  end
  
  def new_decline
    @release = Release.find(params[:id])
  end
  
  def decline
    @release = Release.find(params[:id])
    @release.audio = nil
    @release.cover = nil
    @release.state = 'declined'
    recipients = User.find(:all, :include => [:project_memberships], :conditions => ['project_memberships.project_id = ?', @release.project_id])
    
    if @release.save(false)
      for recipient in recipients do
        ReleaseMailer.deliver_declined_notification(@release, recipient, params[:message])
      end
      flash[:notice] = 'Release has been declined.'
    else 
      flash[:notice] = 'An error occured. Model didn`t get saved. Try again!'
    end
      redirect_to admin_releases_path
  end
  
end
