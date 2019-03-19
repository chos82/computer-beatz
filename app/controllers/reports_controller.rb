class ReportsController < ApplicationController
  layout 'music'
  
  before_filter :login_required, :only => [:comment]

  # GET /music_reports/new
  # GET /music_reports/new.xml
  def new
    @page_title = 'report'
    @music = Music.find(params[:music_id])
  end

  # POST /music_reports
  # POST /music_reports.xml
  def create
    @music = Music.find(params[:music_id])
    unless params[:report].nil?
      @report = Report.new(params[:report])
      @report.user_id = current_user.id
      @report.reportable = @music
      #@report.reportable_type = @music.type.to_s
      if @report.save
        flash[:notice] = "Thanks for your help. The item will be checked."
        redirect_to :controller => :music, :action => 'index'
      else
        render :action => "new"
      end
    else
      flash[:error] = "Please specify the kind of issue."
      render :action => 'new', :id => @music
    end
  end
  
  def comment
    @comment = Comment.find(params[:id])
    @music = Music.find(:first, :include => 'comments', :conditions => ["comments.id = ?", @comment.id])
    @report = Report.new
    @report.user_id = current_user
    @report.reportable = @comment
    if @report.save
      flash[:notice] = "Thanks for your help. The comment will be checked."
      if @music.type == Label
        redirect_to :controller => :labels, :action => 'show', :id => @music.id
      elsif @music.type == Artist
        redirect_to :controller => :artists, :action => 'show', :id => @music.id
      else
        redirect_to :controller => :tracks, :action => 'show', :id => @music.id
      end
    else
      render :action => "new"
    end
  end

end
