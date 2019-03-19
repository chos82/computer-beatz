class InboxController < ApplicationController
  before_filter :login_required
  
  require 'shared_controller.rb'
  include Shared
  
  require 'exceptions.rb'
  include Exceptions
  
  layout 'users'
  
  def index
    @page_title = "Your inbox mail"
    user = User.find(params[:id])
    redirect_to inbox_index_path(current_user) unless user == current_user
      if params[:select] == 'read'
        @messages = Inbox.paginate(:page => params[:page], :include => 'sender',
                                     :conditions => ['reciever = ? AND messages.read = 1', current_user.id],
                                     :order => 'created_at DESC')
        @total = Inbox.count(:all, :conditions => ['reciever = ? AND messages.read = 1', current_user.id])
      elsif params[:select] == 'unread'
        @messages = Inbox.paginate(:page => params[:page], :include => 'sender',
                                     :conditions => ['reciever = ? AND messages.read = 0', current_user.id],
                                     :order => 'created_at DESC')
        @total = Inbox.count(:all, :conditions => ['reciever = ? AND messages.read = 0', current_user.id])
      else
        @messages = Inbox.paginate(:page => params[:page], :include => 'sender',
                                     :conditions => ['reciever = ?', current_user.id],
                                     :order => 'created_at DESC')
        @total = Inbox.count(:all, :conditions => ['reciever = ?', current_user.id])
      end
      @count = Inbox.count(:all, :conditions => ['reciever = ?', current_user.id])
                                     
      set_page_counts( @total, Message::per_page )
      @count = @total + Outbox.count(:all, :conditions => ["sender = ?", current_user.id])
  end
  
  def show
      @page_title = "Mail"
      @message = Inbox.find(params[:id])
      raise AttemptToFakePrivilege.new(@message) unless @message.reciever == current_user
      rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This message isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'      
      rescue AttemptToFakePrivilege
         logger.info("[AttemptToFakeMPrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to see message ID: #{@message.id}.")
         redirect_to users_path
  end
  
  def read
    @message = Message.find(params[:id])
    raise AttemptToFakePrivilege.new(@message) unless @message.reciever == current_user
    @message.read = true
    if @message.save
      redirect_to inbox_path(current_user, @message)
    else
      redirect_to inbox_index_path(current_user)
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This message isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'      
    rescue AttemptToFakePrivilege
       logger.info("[AttemptToFakeMPrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to read message ID: #{@message.id}.")
       redirect_to users_path
  end
  
  def destroy
      @message = Message.find(params[:id])
      raise AttemptToFakePrivilege.new(@message) unless @message.reciever == current_user
      @message.destroy
      redirect_to inbox_index_path(current_user)
      
      rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This message isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'      
      rescue AttemptToFakePrivilege
         logger.info("[AttemptToFakeMPrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to delete message ID: #{@message.id}.")
         redirect_to users_path
  end
  
  def delete_all
      if params[:select] == 'read'
        Inbox.delete_all(["reciever = ? AND messages.read = 1", current_user.id])
      elsif params[:select] == 'unread'
        Inbox.delete_all(["reciever = ? AND messages.read = 0", current_user.id])
      else
        Inbox.delete_all(["reciever = ?", current_user.id])
        redirect_to inbox_index_path(current_user)
      end
  end
  
end
