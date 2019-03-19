class OutboxController < ApplicationController
  before_filter :login_required
  
  require 'shared_controller.rb'
  include Shared
  
  layout 'users'
  
  def index
    @page_title = "Your outbox mail"
    user = User.find(params[:id])
    redirect_to outbox_index_path(current_user) unless user == current_user
      @messages = Outbox.paginate(:page => params[:page], :include => 'reciever',
                                  :conditions => ['sender = ?', current_user.id],
                                  :order => 'created_at DESC')
                                     
      @total = Outbox.count(:all, :conditions => ['sender = ?', current_user.id])
      set_page_counts( @total, Message::per_page )
      @count = @total + Inbox.count(:all, :conditions => ["reciever = ?", current_user.id])
  end
  
  def show
    @page_title = "Mail"
      @message = Outbox.find(params[:id])
  end
  
  def destroy
      @message = Message.find(params[:id])
      raise AttemptToFakePrivilege.new(@message) unless @message.sender == current_user
      @message.destroy
      redirect_to outbox_index_path(current_user)
      
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This message isn`t in the databse. It might have been removed."
        redirect_to :action => 'index'
    rescue AttemptToFakePrivilege
         logger.info("[AttemptToFakeMPrivilege] #{current_user.login} (ID: #{current_user.id}) tryed to delete message ID: #{@message.id}.")
         redirect_to users_path
  end
  
  def delete_all
      Outbox.delete_all(["sender = ?", current_user.id])
      redirect_to outbox_index_path(current_user)
  end
  
  private
  
end
