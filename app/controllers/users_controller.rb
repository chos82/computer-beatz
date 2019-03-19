class UsersController < ApplicationController
  
  require 'shared_controller.rb'
  require 'exceptions.rb'
  include Shared
  include Exceptions
  
  before_filter :not_logged_in_required, :only => [:new, :create] 
  before_filter :login_required, :only => [:edit, :update, :cancel, :destroy]
  
  def index
    @page_title = "Users"
    if params[:order] == 'name'
      @users = User.paginate( :page => params[:page], :order => 'login', :conditions => ['enabled = true'])
    elsif params[:order] == 'activity'
      @users = User.paginate( :page => params[:page], :order => 'no_items DESC, login', :conditions => ['enabled = true'])
    else
      @users = User.paginate( :page => params[:page], :order => 'last_login DESC', :conditions => ['enabled = true'])
    end
    
    set_page_counts(User.count(:all), User::per_page )
  end
  
  def show
    @user = User.find(params[:id])#
    @page_title = "Show user #{h @user.login}"
    redirect_to myprofile_path(current_user) if @user == current_user
    unless @user.enabled
      render :partial => 'account_disabled', :layout => true
    else
      @guestbook_entries = GuestbookEntry.paginate :page => params[:page],
                                   :conditions => ["reciever = ?", @user.id],
                                   :include => 'gb_sender',
                                   :order => 'created_at DESC'
      @guestbook_entry = GuestbookEntry.new
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This user isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def myprofile
    @user = User.find(params[:id])
    @page_title = "Your Profile"
    unless @user == current_user
      redirect_to user_path(@user)
    else
        @guestbook_entries = GuestbookEntry.paginate :page => params[:page],
                                     :conditions => ["reciever = ?", @user.id],
                                     :include => 'gb_sender',
                                     :order => 'created_at DESC'
        @guestbook_entry = GuestbookEntry.new
    end
  end
  
  # render new.rhtml
  def new
  end

  def create
    cookies.delete :auth_token
    # protects against session fixation attacks, wreaks havoc with 
    # request forgery protection.
    # uncomment at your own risk
    # reset_session
    @user = User.new(params[:user])
    @user[:www].gsub! /http:\/\//, ''
    @user[:gender] = 'unknown' unless @user[:gender]
    
    if verify_recaptcha(:model => @user, :message => 'The words you typed do not match the CAPTCHA image.') && @user.save
      flash[:notice] = "Thanks for signing up! A mail with the activation information was sent to you."
      redirect_to login_path
    else
      flash[:error] = "There was a problem creating your account."
      render :action => 'new'
    end
    
  end
  
  def edit
    @page_title = 'Edit your accout'
  end

  def update
    @user = current_user
    params[:user][:www].gsub! /http:\/\//, ''
    params[:user][:gender] = 'unknown' if params[:user][:gender].blank?
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account has been updated."
      redirect_to :action => 'show', :id => current_user.id
    else
      render :action => 'edit'
    end
     rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This user isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
  def cancel

  end
  
  def destroy
    if current_user.enabled
      ActiveRecord::Base.transaction do
        projects = Project.find(:all, :include => [:project_memberships],
                                :conditions => ['project_memberships.user_id = ?', current_user])
        projects.each{|project|
          if project.project_membership.length == 1
            project.destroy
          end
        }
        Rating.delete_all(['user_id = ?', current_user.id])
        Friendship.delete_all(['user_id = ? OR friend_id = ?', current_user.id, current_user.id])
        music = Music.find(:all, :conditions => ['created_by = ?', current_user])
        music.each{|m|
          music.created_by = nil
          music.save
        }
        groups = Group.find(:all, :conditions => ['admin = ?', current_user])
        admin = User.find(:first, :conditions => ["login = 'admin'"])
        groups.each{|group|
          group.admin = admin
          group.save
        }
        current_user.destroy
      end
      flash[:notice] = 'Your account has been deleted.'
      redirect_to 'http://' + SITE_URL
    end
  end
  
  def check_status
    @user = current_user
    render :partial => 'inbox'
  end
  
  def auto_complete_search
    query = params[:search][:query] if params[:search] && params[:search][:query]
    @auto_results = []
    if query && syntax_checker(query)
      @auto_results = User.search(:query => query, :limit => 10)[:objects]
    end
    render :partial => 'auto_results'
  end
  
  def auto_complete_login
    query = params[:query][:login] if params[:query] && params[:query][:login]
    @auto_results = []
    if query && syntax_checker(query)
      @auto_results = User.search(:query => query, :limit => 10)[:objects]
    end
    render :partial => 'auto_results'
  end
  
  def search
    @query = syntax_checker params[:search][:query] if params[:search]
    unless @query
      flash[:error] = "Query '#{h params[:search][:query]}' is not valid syntax." if params[:search]
      redirect_to users_path
    else
      page = params[:page]
      page = 1 unless page
      @results = WillPaginate::Collection.create(page, User::per_page) do |pager|
      result = User.search( :query => @query,
                            :order => params[:order],
                            :offset => pager.offset,
                            :limit => pager.per_page,
                            :count => true )
      # inject the result array into the paginated collection:
        pager.replace(result[:objects])

        unless pager.total_entries
          # the pager didn't manage to guess the total count, do it manually
          @total = pager.total_entries = result[:count]
        end
        set_page_counts( pager.total_entries, pager.per_page )
      end   
    end
  end
  
  def advanced_form
    @page_title = "Search for People"
  end
  
  def advanced_search
    unless params[:query]
      redirect_to :action => 'advanced_form'
      return
    end
    @login = advanced_syntax_checker params[:query][:login]
    
    if params[:query][:gender] == 'both'
      @gender = nil
    else
      @gender = params[:query][:gender]
    end
    if params[:query][:age_from] == 'under 14'
      @age_from = 0
    elsif params[:query][:age_from] == 'over 50'
      @age_from = 51
    else
      @age_from = params[:query][:age_from]
    end
    if params[:query][:age_to] == 'under 14'
      @age_to = 0
    elsif params[:query][:age_to] == 'over 50'
      @age_to = 51
    else
      @age_to = params[:query][:age_to]
    end
    if params[:query][:country] == 'all'
      @country = nil
    else
      @country = params[:query][:country]
    end
    if ( !@login || ((@login.blank? || @login == '*') && @gender.blank? && @age_from.blank? && @age_to.blank? && @country.blank? ))
      flash[:error] = "Query '#{params[:query][:login]}' is not valid syntax."
      redirect_to :action => 'advanced_form'
    else
    @order = params[:order]
    page = params[:page]
    page = 1 unless page
    @results = WillPaginate::Collection.create(page, User.per_page) do |pager|
      result = User.search :query => @login,
                           :order => @order,
                           :gender => @gender,
                           :age_from => @age_from,
                           :age_to => @age_to,
                           :country => @country,
                           :offset => pager.offset,
                           :limit => pager.per_page,
                           :count => true
      # inject the result array into the paginated collection:
      pager.replace(result[:objects])
      unless pager.total_entries
        # the pager didn't manage to guess the total count, do it manually
        pager.total_entries = result[:count]
      end
      set_page_counts( pager.total_entries, pager.per_page )
    end
    end
  end
  
  def forbidden
    @page_title = 'Access denied'
  end
  
  def mytaggings
    @page_title = "Your taggings"
    user = User.find(params[:id])
    unless user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      unless user == current_user
        redirect_to tagged_user_path(user)
      else
        do_tagged(current_user)
      end
    end
  end
  
  def tagged
    @user = User.find params[:id]#
    unless @user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      @page_title = "#{h @user.login}`s taggings"
      if @user == current_user
        redirect_to mytaggings_path(current_user)
      end
      redirect_to forbidden_users_path unless show_page?(@user, @user.tagged_privacy)
      
      do_tagged(@user)
    end
  end
  
  def tag
    @user = User.find(params[:id])
    unless @user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      @page_title = "Tag #{params[:tag]} for user #{h @user.login}"
      if @user == current_user
        redirect_to mytag_path(current_user, :tag => params[:tag])
      end
      redirect_to forbidden_users_path unless show_page?(@user, @user.tagged_privacy)
      
      do_tag(@user)
    end
  end
  
  def mytag
    user = User.find(params[:id])
    unless user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      @page_title = "Your tag #{params[:tag]}"
      unless user == current_user
        redirect_to tagged_by_user_url(user, :tag => params[:tag])
      else
        do_tag(current_user)
      end
    end 
  end
  
  def mytags
    user = User.find(params[:id])
    unless user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      @page_title = "All your tags."
      unless user == current_user
        redirect_to tags_user_url(user)
      else
        @tags = current_user.tag_counts(:order => params[:view])
        @alpha_map = make_alpha_map @tags
      end
    end
  end
  
  def tags
    @user = User.find(params[:id])
    unless @user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      @page_title = "All your tags."
      if @user == current_user
        redirect_to mytags_url(@user)
      end
      redirect_to forbidden_users_path unless show_page?(@user, @user.tagged_privacy)
      
      @tags = @user.tag_counts(:order => params[:view])
      @alpha_map = make_alpha_map @tags
    end
  end
  
  def favourites
    @user = User.find(params[:id])
    unless @user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      @page_title = "Favourites of #{h @user.login}"
      if @user == current_user
        redirect_to myfavourites_path(current_user)
      end
      redirect_to forbidden_users_path unless show_page?(@user, @user.favourites_privacy)
      
      do_favourites(@user)
    end  
  end
  
  def myfavourites
    @page_title = "Your favourites"
    user = User.find(params[:id])
    unless user.enabled
      render :partial => 'accout_disabled', :layout => true
    else
      unless user == current_user
        redirect_to favourites_user_path(user)
      else
        do_favourites(current_user)
      end
    end
  end
  
  def myprojects
    if logged_in?
      unless current_user.enabled
        render :partial => 'accout_disabled', :layout => true
      else
        @page_title = "Your projects"
        @projects = Project.find(:all,
                                  :include => ['project_memberships'],
                                  :conditions => ["project_memberships.user_id = ? AND project_memberships.status = 'active'", current_user.id])
      end
    else
      redirect_to projects_path
    end
  end
  
  private
  
  def make_alpha_map(coll)
    alpha_map = {}
    alphabet = ('A'..'Z').to_a << 'others'
    alphabet.each{|l|
      alpha_map.merge!({l => false})
    }
    ev = "case c.name[0,1]\n"
    alphabet.each{|a| ev += "when '#{a.downcase}' then alpha_map['#{a}'] = true\n" }
    ev += 'end'
    coll.each{|c|
      eval ev
    }
    alpha_map
  end
  
  def do_tagged(user)
    @tagged_items = Music.find_tagged_by(user, :on => :tags, :order => ['first_time_tagged DESC']).paginate(:page => params[:page], :per_page => 20)
                                
    total = Music.count( :all, :include => [:taggings], :conditions => ["taggings.tagger_id = ?", user.id] )
    set_page_counts( total, Music.per_page )
  end
  
  def do_tag(user)
    @tagged_items = Music.paginate( :all, :page => params[:page],
                                :include => [:taggings => :tag],
                                :conditions => ["taggings.tagger_id = ? AND tags.name = ?", user, params[:tag]],
                                :order => 'music.name ASC')
    total = Music.count( :all, :include => [:taggings => :tag],
                            :conditions => ["taggings.tagger_id = ? AND tags.name = ?", user, params[:tag]] )
    set_page_counts( total, Music.per_page )
  end
  
  def do_favourites(user)
    if params[:order] == 'name'
      @music = Music.paginate( :page => params[:page], :include => 'users', :conditions => ["users.id = ?", user], :order => 'name' )
    elsif params[:order] == 'comments'
      @music = Music.paginate( :page => params[:page], :include => 'users', :conditions => ["users.id = ?", user], :order => 'comments_count DESC, name' )
    elsif params[:order] == 'last_commented'
      @music = Music.paginate( :page => params[:page], :include => ['users', 'comments'], :conditions => ["users.id = ?", @ser], :order => 'comments.created_at DESC, name' )
    elsif params[:order] == 'loves'
      @music = Music.paginate(:page => params[:page], :include => 'users', :conditions => ["users.id = ?", user], :order => 'favourites_count DESC, name')
    elsif params[:order] == 'rating'
      @music = Music.paginate(:page => params[:page], :include => ['users', 'ratings'], :conditions => ["users.id = ?", user], :group => 'music.id', :order => 'AVG(ratings.rating) DESC, name')
    else
      @music = Music.paginate(:page => params[:page], :include => 'users', :conditions => ["users.id = ?", user], :order => 'music.created_at DESC, name')
    end  
    
    set_page_counts( Music.count(:all, :include => 'users', :conditions => ["users.id = ?", user]), Music::per_page )
  end
  
end
