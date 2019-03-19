class Admin::MusicController < ApplicationController
  layout 'admin'
  
  before_filter :check_administrator_role
  
  def index
    redirect_to :action => :reported_entries
  end
  
  def destroy
    @music = Music.find(params[:id])
    @music.destroy

    redirect_to(:action => 'reported_entries')
  end

  def reported_entries
    @reports = Report.find(:all, :include => 'reportable', :conditions => ["reportable_type = 'Music'"])
    render :partial => 'music', :layout => true
  end
  
end
