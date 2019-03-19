class ProjectsController < ApplicationController
  layout 'application'
  
  require 'exceptions.rb'
  include Exceptions
  
  before_filter :login_required, :except => [:index, :show, :add_comment, :member]
  
  # GET /projects
  # GET /projects.xml
  def index
    @page_title = "Creative Commons Projects"
    @projects = Project.find(:all,
                             :select => ['DISTINCT projects.*'],
                             :joins => [:releases],
                             :conditions => ["releases.state = 'released'"],
                             :order => "projects.updated_at DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @projects }
    end
  end

  # GET /projects/1
  # GET /projects/1.xml
  def show
    @project = Project.find(params[:id], :include => ['users'])#, :joins => :releases)
    @page_title = "Creative Commons Project #{h @project.name}"
    
    ratings = Rating.find(:all,
                          :joins => ['LEFT OUTER JOIN releases ON ratings.rateable_id = releases.id'],
                          :conditions => ["rateable_type ='Release' AND releases.project_id = ?", @project.id])
    sum = 0
    ratings.each{|rating|
      sum += rating.rating
    }
    @rating_avg = ratings.length != 0 ? (sum / ratings.length).round : 0
    @published = Release.find(:all, :conditions => ["state = 'released' AND project_id = ?", @project.id], :order => ['created_at DESC'])
    @comments = Comment.paginate :page => params[:page],
                                 :conditions => ["commentable_id = ? AND commentable_type ='Project'", @project.id],
                                 :order => 'created_at DESC'
    @comment = Comment.new
    if @project.is_member? current_user
      render 'member'
    else
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @project }
      end
    end
    
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "This project isn`t in the databse. It might have been removed."
      redirect_to :action => 'index'
  end
  
  def pending
    @page_title = "Pending Releases"
    @project = Project.find(params[:id])
    raise AttemptToFakePrivilege.new(@project) unless @project.is_member? current_user
    @pending = Release.find(:all, :conditions => ["state = 'uploaded' AND project_id = ?", @project.id])
    @declined = Release.find(:all, :conditions => ["state = 'declined' AND project_id = ?", @project.id])
    raise AttemptToFakePrivilege.new(@topic) unless @project.is_member? current_user
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @project }
    end
  end

  # GET /projects/new
  # GET /projects/new.xml
  def new
    @page_title = "New Project"
    @project = Project.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @project }
    end
  end

  # GET /projects/1/edit
  def edit
    @project = Project.find(params[:id])
    raise AttemptToFakePrivilege.new(@project) unless @project.is_member? current_user
    @page_title = "Edit #{h @project.name}"
  end
  
  def invite
    @project = Project.find(params[:id], :include => ['users'], :conditions => ["project_memberships.status = 'active'"])
    raise AttemptToFakePrivilege.new(@project) unless @project.is_member? current_user
    @page_title = "Invite someone to #{h @project.name}"
    @pending = User.find(:all, :include => ['project_memberships'], :conditions => ["project_memberships.status = 'invited'"])
  end
  
  def do_invitation
    @project = Project.find(params[:id])
    raise AttemptToFakePrivilege.new(@project) unless @project.is_member? current_user
    if params[:invitation][:reciever].blank?
      flash[:error] = "Fill in a name."
      redirect_to :action => 'invite'
    end
    @reciever = User.find(:first, :conditions => ["login = ?", params[:invitation][:reciever]])
    raise AttemptToFakePrivilege.new(@project) unless @project.is_member? current_user
    unless @reciever
      flash[:error] = "Reciever '#{params[:message][:reciever]}' does not exist."
      redirect_to :action => 'invite'
    end
    invitation = ProjectMembership.new(:project => @project, :user => @reciever, :status => 'invited')
    if invitation.save
      flash[:notice] = "Invitation was sent successfully."
      redirect_to :action => 'invite'
    end
  
    rescue AttemptToFakePrivilege
      logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to update #{@project.title}.")
      redirect_to projects_path
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "This project isn`t in the databse. It might have been removed."
      redirect_to :action => 'index'
  end

  # POST /projects
  # POST /projects.xml
  def create
    @project = Project.new(params[:project])
    @membership = ProjectMembership.new(:project => @project, :user => current_user, :status => 'active')

    respond_to do |format|
      ActiveRecord::Base.transaction do
        if @project.save && @membership.save
          flash[:notice] = 'Project was successfully created. You can invite others to be a member of the project and upload audio files now.</br>' +
                           'The project will not be displayed to others till there is a accepted release.</br>'
          format.html { redirect_to(@project) }
          format.xml  { render :xml => @project, :status => :created, :location => @project }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
        end
      end
    end
  end

  # PUT /projects/1
  # PUT /projects/1.xml
  def update
    @project = Project.find(params[:id])
    raise AttemptToFakePrivilege.new(@project) unless @project.is_member? current_user
    @project.name = params[:project][:name]
    @project.description = params[:project][:description]
    @project.logo = ! params[:project][:logo].blank? ? params[:project][:logo] : @project.logo

    respond_to do |format|
      if @project.save
        flash[:notice] = 'Project was successfully updated.'
        format.html { redirect_to(@project) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @project.errors, :status => :unprocessable_entity }
      end
    end
    
    rescue AttemptToFakePrivilege
         logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to update #{@project.title}.")
         redirect_to projects_path
  end
  
  def auto_complete_reciever
    @auto_results = User.find(:all, :conditions => ["login LIKE ?", '%' + params[:invitation][:reciever] + '%'], :limit => 10)
    render :partial => 'users/auto_results'
  end
  
  def check_reciever
    @reciever = User.find(:first, :conditions => ["login = ?", params[:reciever]])
    if @reciever
      @found = true
    else
      @found = false
    end
    render 'shared/check_reciever', :layout => false
  end
  
  def logo
    @project = Project.find(params[:id])
    render :layout => false
  end
  
  def add_comment
    @comment = Comment.new(params[:comment])
    @comment.user = current_user
    entry = Project.find(params[:id])
    @comment.commentable = entry
    
    ActiveRecord::Base.transaction do
      respond_to do |format|
        if @comment.save
          flash[:notice] = 'Comment was successfully created.'
          format.html { redirect_to(:controller => 'projects', :action => 'show', :id => params[:id]) }
          format.xml  { render :xml => @comment, :status => :created, :location => @comment }
        else
          format.html { redirect_to :controller => 'projects', :action => "show", :id => params[:id] }
          format.xml  { redirect_to :xml => @comment.errors, :status => :unprocessable_entity }
        end
      end
    end
  end
  
  def delete_comment
    @comment = Comment.find(params[:comment])
    @project = Project.find(params[:id])
    raise AttemptToFakePrivilege.new(@project) unless @project.is_member? current_user
    
    if @comment.destroy
      flash[:notice] = "Comment was successfully deleted."
      redirect_to @project
    end
    rescue AttemptToFakePrivilege
      logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to access a restricted action of project #{@project.title}.")
      redirect_to projects_path
  end
  
  def favourized_by
    @project = Project.find( params[:id] )
    @users = User.paginate( :page => params[:page],
                            :include => ['favourites'],
                            :conditions => [ "favourites.favourizable_type = 'Project' AND favourites.favourizable_id = ?", params[:id] ] )
    count = User.count( :all, :include => ['favourites'],
                        :conditions => [ "favourites.favourizable_type = 'Music' AND favourites.favourizable_id = ?", params[:id] ] )
                          
    set_page_counts count, @users::per_page
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def stop_comment_notifications
    project = Project.find(params[:id])
    raise AttemptToFakePrivilege.new(@project) unless project.is_member? current_user
    membership = ProjectMembership.find(:first, :conditions => ['user_id = ? AND project_id = ?', current_user.id, project.id])
    membership.comment_notification = false
    if membership.save
      flash[:notice] = 'Now you will receive NO more e-mail notifications on new comments (on the project and all it`s releases).'
      redirect_to project_path(project)
    else
      flash[:error] = 'Something went wrong. Please try again!'
    end
    
    rescue AttemptToFakePrivilege
      logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to access a restricted action of project #{project.title}.")
      redirect_to projects_path
  end
  
  def start_comment_notifications
    project = Project.find(params[:id])
    raise AttemptToFakePrivilege.new(@project) unless project.is_member? current_user
    membership = ProjectMembership.find(:first, :conditions => ['user_id = ? AND project_id = ?', current_user.id, project.id])
    membership.comment_notification = true
    if membership.save
      flash[:notice] = 'Now you will receive e-mail notifications on new comments (on the project and all it`s releases).'
      redirect_to project_path(project)
    else
      flash[:error] = 'Something went wrong. Please try again!'
    end
    
    rescue AttemptToFakePrivilege
      logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to access a restricted action of project #{project.title}.")
      redirect_to projects_path
  end
      
end
