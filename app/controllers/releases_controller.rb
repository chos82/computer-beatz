class ReleasesController < ApplicationController
  
  require 'shared_controller.rb'
  include Shared
  require 'exceptions.rb'
  include Exceptions
  
  layout 'application'
  
  before_filter :login_required, :except => [:index, :show, :cover]
  before_filter :check_administrator_role, :only => [:preview]
    
  # GET /releases
  # GET /releases.xml
  def index
    @page_title = "Creative Commons Releases"
    @releases = Release.paginate(:page => params[:page], :conditions => ["state = 'released'"], :order => ['created_at DESC'])

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @releases }
    end
  end

  # GET /releases/1
  # GET /releases/1.xml
  def show
   @release = Release.find(params[:id], :conditions => ["state = 'released'"])
   @page_title = "Creative Commons: #{h @release.project.name} - #{h @release.name}"
   if @release.project.users.include? current_user
     redirect_to :action => 'member'
   else
     @ur = Rating.find(:first, :conditions => [ "user_id = ? AND rateable_id = ?", current_user.id, params[:id] ]) if current_user
     @rating_count = Rating.count(:conditions => ["rateable_id = ? AND rateable_type ='Release'", @release.id])
     
     @comments = Comment.paginate :page => params[:page],
                                    :conditions => ["commentable_id = ? AND commentable_type ='Release'", @release.id],
                                    :order => 'created_at DESC'
     @comment = Comment.new
  
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @release }
      end
    end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "The item could not be found. It might have been removed."
      redirect_to :action => 'index'
  end
  
   def preview
   @release = Release.find(params[:id])
   @ur = Rating.find(:first, :conditions => [ "user_id = ? AND rateable_id = ?", current_user.id, params[:id] ]) if current_user
   @rating_count = Rating.count(:conditions => ["rateable_id = ? AND rateable_type ='Release'", @release.id])
    
   @comments = Comment.paginate :page => params[:page],
                                :conditions => ["commentable_id = ? AND commentable_type ='Release'", @release.id],
                                :order => 'created_at DESC'
   @comment = Comment.new
  
   respond_to do |format|
     format.html # show.html.erb
     format.xml  { render :xml => @release }
   end

    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "The item could not be found. It might have been removed."
      redirect_to :action => 'index'
  end
  
  def member
   @release = Release.find(params[:id], :conditions => ["state = 'released'"])
   @page_title = "Creative Commons: #{h @release.project.name} - #{h @release.name}"
   raise AttemptToFakePrivilege.new(@release) unless @release.project.is_member? current_user
   @ur = Rating.find(:first, :conditions => [ "user_id = ? AND rateable_id = ?", current_user.id, params[:id] ]) if current_user
   @rating_count = Rating.count(:conditions => ["rateable_id = ? AND rateable_type ='Release'", @release.id])
   
   @comments = Comment.paginate :page => params[:page],
                                  :conditions => ["commentable_id = ? AND commentable_type ='Release'", @release.id],
                                  :order => 'created_at DESC'
   @comment = Comment.new

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @release }
    end
    
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "The item could not be found. It might have been removed."
      redirect_to :action => 'index'
    rescue AttemptToFakePrivilege
      logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to access a restricted action of #{@release.title}.")
      redirect_to releases_path
  end

  # GET /releases/new
  # GET /releases/new.xml
  def new
    @release = Release.new
    @project = Project.find(params[:project_id])
    @page_title = "New Release for #{h @project.name}"
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @release }
    end
    
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "The associated project could not be found. It might have been removed."
      redirect_to :action => 'index'
  end

  # GET /releases/1/edit
  def edit
    @release = Release.find(params[:id])
    @page_title = "Edit #{h @release.name}"
  end
  
  def destroy
     @release = Release.find(params[:id])
     raise AttemptToFakePrivilege.new(@release) unless @release.project.is_member? current_user
     proj = @release.project
     
     ActiveRecord::Base.transaction do
       Rating.delete_all(["rateable_id = ? AND rateable_type = 'Release'", @release.id])
       @release.destroy
     end
     
     redirect_to member_project_path proj
      
      rescue ActiveRecord::RecordNotFound
        flash[:notice] = "The item could not be found. It might have been removed."
        redirect_to :action => 'index'
      rescue AttemptToFakePrivilege
        logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to access a restricted action of #{@release.title}.")
        redirect_to releases_path
  end

  # POST /releases
  # POST /releases.xml
  def create
    @release = Release.new(params[:release])
    @project = Project.find(params[:project_id])
    raise AttemptToFakePrivilege.new(@project) unless @project.is_member? current_user
    raise AttemptToFakePrivilege.new(@project) unless @project.has_quota? current_user
    
    @release.project = @project
    @release.state = 'uploaded'
    unless @release.audio?
      @release.errors.add(:audio, " file must be set!")
      render :action => :new
    else
    
      respond_to do |format|
        if @release.save
          flash[:notice] = 'Release was successfully created.'
          format.html { redirect_to(member_project_path(@release.project)) }
          format.xml  { render :xml => @release, :status => :created, :location => @release }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @release.errors, :status => :unprocessable_entity }
        end
      end
      
    end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "The associated project could not be found. It might have been removed."
      redirect_to :controller => 'projects', :action => 'member', :id => @project.id
    rescue AttemptToFakePrivilege
      logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to access a restricted action of project #{@project.name}.")
      redirect_to releases_path
  end

  # PUT /releases/1
  # PUT /releases/1.xml
  def update
    @release = Release.find(params[:id])
    raise AttemptToFakePrivilege.new(@release) unless @release.project.is_member? current_user
    @release.name = params[:release][:name]
    @release.description = params[:release][:description]
    @release.cover = ! params[:release][:cover].blank? ? params[:release][:cover] : @release.cover

    respond_to do |format|
      if @release.save
        flash[:notice] = 'Release was successfully updated.'
        format.html { redirect_to(@release) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @release.errors, :status => :unprocessable_entity }
      end
    end
    rescue AttemptToFakePrivilege
      logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to access a restricted action of project #{@release.title}.")
      redirect_to releases_path
  end

  def add_comment
    @comment = Comment.new(params[:comment])
    @comment.user = current_user
    entry = Release.find(params[:id])
    @comment.commentable = entry
    
    ActiveRecord::Base.transaction do
      respond_to do |format|
        if @comment.save
          flash[:notice] = 'Comment was successfully created.'
          format.html { redirect_to(:controller => 'releases', :action => 'show', :id => params[:id]) }
          format.xml  { render :xml => @comment, :status => :created, :location => @comment }
        else
          format.html { redirect_to :controller => 'releases', :action => "show", :id => params[:id] }
          format.xml  { redirect_to :xml => @comment.errors, :status => :unprocessable_entity }
        end
      end
    end
  end
  
  def delete_comment
    @comment = Comment.find(params[:comment])
    @release = Release.find(params[:id])
    raise AttemptToFakePrivilege.new(@release) unless @release.project.is_member? current_user
    
    if @comment.destroy
      flash[:notice] = "Comment was successfully deleted."
      redirect_to @release
    end
    rescue AttemptToFakePrivilege
      logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to access a restricted action of project #{@release.title}.")
      redirect_to releases_path
  end

  def make_favourite
      @item = Release.find(params[:id])
      @item.users << current_user
      @item = Release.find(params[:id])
      @love = true
      respond_to do |format|
        format.js
      end 
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def remove_from_favourites
    @item = Release.find(params[:id])
    Favourite.destroy_all(["favourizable_type ='Release' AND favourizable_id = ? AND user_id = ?", @item.id, current_user])
    @love = false
    respond_to do |format|
      format.js
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def favourized_by
    @release = Release.find( params[:id] )
    @users = User.paginate( :page => params[:page],
                            :include => ['favourites'],
                            :conditions => [ "favourites.favourizable_type = 'Release' AND favourites.favourizable_id = ?", @release.id ] )
    count = User.count( :all, :include => ['favourites'],
                        :conditions => [ "favourites.favourizable_type = 'Release' AND favourites.favourizable_id = ?", @release.id ] )
                          
    set_page_counts count, @users::per_page
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def rate
    @item = Release.find(params[:id])
    old_rating = Rating.find(:first, :conditions => [ "user_id = ? AND rateable_id = ?", current_user.id, @item.id ])
    unless old_rating
      @ur = Rating.new(:rating => params[:rating], :user_id => current_user.id)
      @item.add_rating @ur
      @rating_count = @item.ratings.size
      respond_to do |format|
        format.js
      end
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def add_comment
    @comment = Comment.new(params[:comment])
    @comment.user = current_user if logged_in?
    @release = Release.find(params[:id])
    @comment.commentable = @release
    
      respond_to do |format|
        if( !logged_in? && verify_recaptcha ) ||
             logged_in?
          if @comment.save
            saved = true
          end
        else
          flash[:error] = 'The words you typed do not match the CAPTCHA image.'
        end
        if saved
          flash[:notice] = 'Comment was successfully created.'
          format.html { redirect_to(:controller => 'releases', :action => 'show', :id => params[:id]) }
          format.xml  { render :xml => @comment, :status => :created, :location => @comment }
        else
           @comments = Comment.paginate :page => params[:page],
                                    :conditions => ["commentable_id = ? AND commentable_type ='Release'", @release.id],
                                    :order => 'created_at DESC'
          format.html { render :controller => 'releases', :action => "show", :id => params[:id] }
          format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
        end
    end
  end
  
  def cover
    @release = Release.find(params[:id])
    @page_title = "Cover of #{@release.project.name} - #{@release.project}"
    render :layout => false
    
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This item isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
end
