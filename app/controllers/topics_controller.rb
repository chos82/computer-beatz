class TopicsController < ApplicationController
  layout 'groups'
  
  before_filter :login_required, :except => [:index, :show]
  before_filter :find_group
  before_filter :membership_required, :except => [:index, :show]
  before_filter :show_content, :only => [:index, :show]
  
  require 'shared_controller.rb'
  include Shared
  require 'exceptions.rb'
  include Exceptions
  
  # GET /topics
  # GET /topics.xml
  def index
    @page_title = "Topics of group: #{@group.title}"
    if params[:order] == 'noPosts'
      @topics = Topic.paginate( :page => params[:page],
                                :conditions => ["group_id = ?", @group.id],
                                :order => ['news_messages_count DESC'] )
    elsif params[:order] == 'activity'
      @topics = Topic.paginate( :page => params[:page],
                                :conditions => ["group_id = ?", @group.id],
                                :order => ['updated_at DESC'] )
    else
      @topics = Topic.paginate( :page => params[:page],
                                :conditions => ["group_id = ?", @group.id],
                                :order => ['title ASC'] )
    end
    
    set_page_counts( Topic.count(:all, :conditions => ['group_id = ?', @group.id]), Topic::per_page )
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @topics }
    end
  end

  # GET /topics/1
  # GET /topics/1.xml
  def show
    @topic = Topic.find(params[:id])
    @page_title = "#{@topic.title}  - Group: #{@group.title}"
    
    #if accessed from search, we might need to redirect to the right page
    if params[:s_id]
      message = NewsMessage.find_by_id(params[:s_id])
      page = NewsMessage.count( :conditions => ['thread_id = ? AND created_at < ?', @topic, message.created_at] ) / NewsMessage::per_page
      page += 1
      redirect_to :action => :show, :anchor => params[:s_id], :page => page, :h_id => params[:s_id]
    else
      @news = NewsMessage.paginate( :page => params[:page],
                                  :conditions => ['thread_id = ?', @topic],
                                  :order => 'created_at ASC')
                                  
      set_page_counts( NewsMessage.count(:all, :conditions => ['thread_id = ?', @topic.id]), NewsMessage::per_page )
    
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @topic }
      end
    end
  end

  # GET /topics/new
  # GET /topics/new.xml
  def new
    @topic = Topic.new
    @page_title = "New topic for group: #{@group.title}"

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @topic }
    end
  end

  # POST /topics
  # POST /topics.xml
  def create
    @topic = Topic.new(params[:topic])    
    @topic.group = @group
    @topic.user = current_user

    respond_to do |format|
      if @topic.save
        flash[:notice] = 'Topic was successfully created.<br /><b>You should post a message!</b>'
        format.html { redirect_to(group_topic_path(@group, @topic)) }
        format.xml  { render :xml => @topic, :status => :created, :location => @topic }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @topic.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /topics/1
  # DELETE /topics/1.xml
  def destroy
    @topic = Topic.find(params[:id])
    raise AttemptToFakePrivilege.new(@topic) unless(@group.admin == current_user)
    @topic.destroy

    respond_to do |format|
      format.html { redirect_to(group_topics_url(@group)) }
      format.xml  { head :ok }
    end
    rescue AttemptToFakePrivilege
         logger.info("[AttemptToFakePrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to delete topic #{@topic.title}, without having admin rights.")
         redirect_to groups_path
  end
  
  
  protected
  def find_group
    @group = Group.find(params[:group_id])
  end
  
  def membership_required
    raise AttemptToFakeMembership.new(@group) unless current_user.is_member?(@group) 
    rescue AttemptToFakeMembership
         logger.info("[AttemptToFakeMembership] #{current_user.login} (ID: #{current_user.id}) tryed to access a non-public action of #{@group.title}.")
         redirect_to groups_path
  end
  
  def show_content
    return if @group.public
    if current_user
       if current_user.is_member?(@group)
         return
       end
   end
   raise AttemptToFakeMembership.new(@group)
 rescue AttemptToFakeMembership
      phrase = logged_in? ? current_user.login + ' ID: ' + current_user.id + ' ' : 'A visitor '  
      logger.info('[AttemptToFakeMembership]' + phrase + "tryed to access non-public information of #{@group.title}.")
      redirect_to groups_path
  end
 
end
