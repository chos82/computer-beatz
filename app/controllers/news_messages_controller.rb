class NewsMessagesController < ApplicationController
  layout 'groups'
  
  before_filter :login_required, :find_group, :find_topic
  
  def new
    if !logged_in? || logged_in? && !current_user.is_member?(@group)
      flash[:notice] = "You have to be a member of the group to post!"
      redirect_to group_path @group
    end
    @message = NewsMessage.new
    
    @news = NewsMessage.find(    :all,
                                 :include => [:sender],
                                 :conditions => ['news_messages.thread_id = ?', @topic.id],
                                 :order => "news_messages.created_at DESC",
                                 :limit => 10)
  end

  def edit
    @message = NewsMessage.find(    params[:id],
                                 :include => [:sender])
  end
  
  def create
    if logged_in? && current_user.is_member?(@group) && ( (params[:message][:admin_message] && current_user == @group.admin)  || !(params[:message][:admin_message]) )
      @message = NewsMessage.new(params[:message])
      @message.sender = current_user
      @message.topic = @topic
      @membership = Member.find(:first, :conditions => ["group_id = ? AND user_id = ?", @group.id, current_user.id])
      @membership.no_messages += 1

      ActiveRecord::Base.transaction do
        if @message.save && @membership.save!
          flash[:notice] = 'Post was successful.'
          redirect_to group_topic_path(@group.id, @topic.id, :anchor => @message.id)
        else
          render :action => "new"
        end
      end
    else
      redirect_to groups_path
    end
  end
  
  def update
    @message = NewsMessage.find(params[:id])
    if current_user == @message.sender
      if @message.update_attributes(:subject => params[:news_message][:subject], :text => params[:news_message][:text], :admin_message =>  params[:news_message][:admin_message])
          flash[:notice] = 'Post was successful.'
          redirect_to group_topic_path(@group.id, @topic.id, :anchor => @message.id)
      else
          render :action => "new"
      end
    else
      redirect_to groups_path
    end
  end
  
  def destroy
    if @group.admin == current_user
      @message = NewsMessage.find(params[:id])
      @message.destroy
      redirect_to group_path(@group)
    else
      redirect_to groups_url
    end
  end

  

  private
  
  def find_group
    @group = Group.find(params[:group_id])
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This group isn`t in the databse. It might have been removed."
        redirect_to groups_path
  end
  
  def find_topic
    @topic = Topic.find(params[:topic_id])
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This group isn`t in the databse. It might have been removed."
        redirect_to groups_path
  end

  
end
