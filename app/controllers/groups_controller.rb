class GroupsController < ApplicationController
  before_filter :login_required, :except => [:auto_complete_search, :index, :search, :show]
  
  require 'shared_controller.rb'
  include Shared
  
  require 'exceptions.rb'
  include Exceptions
  
  # GET /groups
  # GET /groups.xml
  def index
    @page_title = "Groups"
    @order = params[:order]
    @visible = params[:visible]
    @public = params[:public]
    cond = ['']
    if @visible == 'true'
      cond[0] += "public = 1"
    elsif @visible == 'false'
      cond[0] += "public = 0"
    end
    if @public == 'true'
      cond[0] += ' AND ' unless cond[0] == ''
      cond[0] += "locked = 0"
    elsif @public == 'false'
      cond[0] += ' AND ' unless cond[0] == ''
      cond[0] += "locked = 1"
    end
    cond = nil if cond[0].blank?
    if @order == 'messages'
      @groups = Group.paginate(:page => params[:page],
                               :conditions => cond,
                               :select => 'DISTINCT groups.*',
                               :joins => ["LEFT OUTER JOIN topics ON topics.group_id = groups.id LEFT OUTER JOIN news_messages ON news_messages.thread_id = topics.id"],
                               :group => ['groups.id'],
                               :order => "COUNT(news_messages.id) DESC, news_messages.id" )
    elsif @order == 'members'
      @groups = Group.paginate(:page => params[:page],
                               :conditions => cond,
                               :include => 'members',
                               :group => ['groups.id'],
                               :order => "COUNT(members.id) DESC, members.id" )
    elsif @order == 'name'
      @groups = Group.paginate(:page => params[:page],
                               :conditions => cond,
                               :order => "title")
    else
      @groups = Group.paginate(:page => params[:page],
                               :conditions => cond,
                               :include => ['topics'],
                               :order => "topics.updated_at DESC")
    end
    
    set_page_counts( Group.count(:all, :conditions => cond), Group::per_page )

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @groups }
    end
  end
  
  # GET /groups/1
  # GET /groups/1.xml
  def show
    @group = Group.find(params[:id])
    @page_title = "Group: #{h @group.title}"
    @news = NewsMessage.find(    :all,
                                 :joins => ['LEFT OUTER JOIN topics ON news_messages.thread_id = topics.id'],
                                 :include => [:sender],
                                 :conditions => ["topics.group_id = ?", @group.id],
                                 :order => "news_messages.created_at DESC",
                                 :limit => 15) 
    
    @message = NewsMessage.new
    @member = Member.find(:first, :conditions => ["group_id = ? AND user_id = ?", @group.id, current_user.id]) if current_user

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @group }
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This group isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
    
  end

  # GET /groups/new
  # GET /groups/new.xml
  def new
    @group = Group.new
    @page_title = "New Group"

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @groups }
    end
  end

  # GET /groups/1/edit
  def edit
    @group = Group.find(params[:id])
    @page_title = "Edit Group #{h @group.title}"
    raise AttemptToFakePrivilege.new(@group) unless @group.admin == current_user
      respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @groups }
      end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This group isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
    rescue AttemptToFakePrivilege
         logger.info("[AttemptToFakeMPrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to edit #{@group.title}.")
         redirect_to groups_path
  end
  
  # PUT /groups/1
  # PUT /groups/1.xml
  def update
    @group = Group.find(params[:id])
    
    raise AttemptToFakePrivilege.new(@group) unless @group.admin == current_user
      respond_to do |format|
        if @group.update_attributes(params[:group])
          flash[:notice] = 'Group was successfully updated.'
          format.html { redirect_to(@group) }
          format.xml  { head :ok }
        else
          format.html { render :action => "edit" }
          format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
        end
      end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This group isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
    rescue AttemptToFakePrivilege
         logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to update #{@group.title}.")
         redirect_to groups_path
  end
  
  # POST /groups
  # POST /groups.xml
  def create
    @group = Group.new(params[:group])
    @group.admin = current_user

    respond_to do |format|
      @group.save
      @group.users << current_user
      ActiveRecord::Base.transaction do
        if @group.save
          flash[:notice] = 'Group was successfully created.'
          format.html { redirect_to(@group) }
          format.xml  { render :xml => @group, :status => :created, :location => @group }
        else
          format.html { render :action => "new" }
          format.xml  { render :xml => @group.errors, :status => :unprocessable_entity }
        end
      end
    end
  end
  
  #currently not used - searches for group.title
  def search_old
    @query = syntax_checker params[:search][:query]
    unless @query
      flash[:error] = "Query '#{h params[:search][:query]}' is not valid syntax."
      redirect_to groups_index_path
    else
      page = params[:page]
      page = 1 unless page
      @results = WillPaginate::Collection.create(page, User::per_page) do |pager|
      result = Group.search( :query => @query,
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
  
  #ferret full-text search
  def search
    @page_title = "Groups full text search"
    @query = params[:search][:query] if params[:search]
    @results = NewsMessage.find_with_ferret(@query,
                                            {:page => params[:page],
                                            :lazy => true,
                                            :per_page => NewsMessage.per_page}, {:include => [:topic, :group]})
    
  end
  
  def auto_complete_search
    query = syntax_checker params[:search][:query]
    unless query
      @auto_results = []
    else
      @auto_results = Group.search(:query => query, :limit => 10)[:objects]
    end
    render :partial => 'auto_results'
  end
  
  def give_away_form
    @group = Group.find(params[:id])
    @page_title = "Give administration of #{h @group.title} away"
    redirect_to groups_path unless @group.admin == current_user
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This group isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
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
    render :layout => false
  end
  
  def give_away
    @group = Group.find(params[:id])
    redirect_to groups_path unless @group.admin == current_user
    @reciever = User.find_by_login(params[:invitation][:reciever])
    if @reciever.blank?
      flash[:error] = "The choosen user does not exist."
      redirect_to :action => 'give_away_form'
    else
      invited = GroupAdminInvitation.find(:all, :conditions => ["sender = ? AND reciever = ? AND group_id = ?", current_user.id, @reciever.id, @group.id])
      if invited.blank?
        @invitation = GroupAdminInvitation.new()
        @invitation.sender = current_user
        @invitation.reciever = @reciever
        @invitation.group = @group
        if @invitation.save
          flash[:notice] = "User '#{@reciever.login}' has been invited to become the new admin of '#{@group.title}'."
          redirect_to( group_url(@group) )
        else
          flash[:error] = 'Could not create the invitation. Please try again.'
          redirect_to :action => 'give_away_form'
        end
      else
        flash[:notice] = "You already invited user '#{@reciever.login}'."
        redirect_to group_url(@group)
      end
      #@message = Message.new(:reciever => @reciever,
      #                       :sender => User.find_by_login('admin'),
      #                       :subject => "[computer-beatz] You are invited to become the admin of '#{@group.title}'",
      #                       :text => "User \"'#{@group.admin.login}'\":http://www.computer-beatz.de/users/#{@group.admin.id},\n" + 
      #                       "currently the admin of group \"'#{@group.title}'\":http://www.computer-beatz.de/groups/#{@group.id},\n" + 
      #                       "don`t want to do the admin stuff anymore. He asks you to become the new admin!\n\n" + 
      #                       "By visiting \"accept/decline\":http://www.computer-beatz.de/users/#{@reciever.id}/invitations\n" +
      #                       "you can either accept or decline the invitation. All your pending invitations are \n" +
      #                       "shown there.\n\n" +
      #                       "Cheers,\nThe computer-beatz admin")
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This group isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end

  # DELETE /groups/1
  # DELETE /groups/1.xml
  def destroy
    @group = Group.find(params[:id])
    @group.destroy

    if @group.admin == current_user
      respond_to do |format|
        format.html { redirect_to(groups_url) }
        format.xml  { head :ok }
      end
    else
      redirect_to groups_path
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This group isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
  end
  
end
