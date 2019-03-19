class MessagesController < ApplicationController
  layout 'users'
  
  before_filter :find_user, :only => [:new, :create]
  before_filter :login_required
  
  def new
    reciever_count = Inbox.count(:all, :conditions => ["reciever = ?", @user.id]) +
                     Outbox.count(:all, :conditions => ["sender = ?", @user.id])
    sender_count = Inbox.count(:all, :conditions => ["reciever = ?", current_user.id]) +
                   Outbox.count(:all, :conditions => ["sender = ?", current_user.id])
    if reciever_count > 500
      flash[:error] = "Sorry. The mailbox of <strong>#{@user.login}</strong> is full."
      redirect_to user_path(@user)
    end
    if sender_count > 500
      flash[:error] = "Your mailbox is full. You have to delete massages, before you can send or recieve new ones."
      redirect_to inbox_index_path(current_user)
    end
    @message = Message.new
  end
  
  def create
    @message = Message.new(params[:message])
    ib = Inbox.new(params[:message])
    ib.sender = current_user
    ib.reciever = @user
    
    ActiveRecord::Base.transaction do
      if params[:save_to_outbox]
        ob = Outbox.new(params[:message])
        ob.reciever = @user
        ob.sender = current_user
        ob.save
      end
      
      if ib.save
        flash[:notice] = 'Delivery was successful.'
        redirect_to(user_path(@user))
      else
        render :action => "new"
      end
    end
  end
  
  def reply
    @original = Message.find(params[:id])
    @message = Message.new
    @message.subject = "RE: " + @original.subject
    @message.text = "\n\n\n---\n" + 
                          "ORIGINAL MESSAGE\n" + 
                          "FROM: #{@original.sender.login}\n" + 
                          "#{@original.created_at}\n" + 
                          "---------------------------------\n\n" + @original.text
    redirect_to users_url unless @original.reciever == current_user
    reciever_count = Inbox.count(:all, :conditions => ["reciever = ?", @original.reciever.id]) +
                     Outbox.count(:all, :conditions => ["sender = ?", @original.reciever.id])
    sender_count = Inbox.count(:all, :conditions => ["reciever = ?", @original.sender.id]) +
                   Outbox.count(:all, :conditions => ["sender = ?", @original.sender.id])
    if reciever_count > 500
      flash[:error] = "Sorry. The mailbox of <strong>#{@original.reciver.login}</strong> is full."
      redirect_to inbox_index_path(current_user)
    end
    if sender_count > 500
      flash[:error] = "Your mailbox is full. You have to delete massages, before you can send or recieve new ones."
      redirect_to inbox_index_path(current_user)
    end
  end
  
  def send_reply
    @message = Message.new(params[:message])
    @original = Message.find(params[:id])
    redirect_to users_url unless @original.reciever == current_user
    #  @original #set replied true
    @message.sender = @original.reciever
    @message.reciever = @original.sender
    @original.replied = true
    @original.read = true
    
    ActiveRecord::Base.transaction do
      if params[:save_to_outbox]
        ob = Outbox.new(:sender => @message.sender, :reciever => @message.reciever, :subject => @message.subject, :text => @message.text)
        ob.save
      end
      ib = Inbox.new(:sender => @message.sender, :reciever => @message.reciever, :subject => @message.subject, :text => @message.text)
      
      if ib.save && @original.save
        flash[:notice] = 'Delivery was successful.'
        redirect_to inbox_index_path(current_user)
      else
        flash[:error] = "The message could not be delivered, sorry."
        render :action => "reply"
      end
    end
    rescue ActiveRecord::RecordNotFound
      flash[:notice] = "Original message could not be found."
      redirect_to inbox_index_path(current_user)
  end
  
  def compose
    @message = Message.new
  end
  
  def auto_complete_reciever
    @auto_results = User.find(:all, :conditions => ["login LIKE ?", '%' + params[:message][:reciever] + '%'], :limit => 10)
    render :partial => 'users/auto_results'
  end
  
  def check_reciever
    @reciever = User.find(:first, :conditions => ["login = ?", params[:reciever]])
    if @reciever
      @found = true
      reciever_count = Inbox.count(:all, :conditions => ["reciever = ?", @reciever.id]) +
                     Outbox.count(:all, :conditions => ["sender = ?", @reciever.id])
      if reciever_count < 500
        @free_mail = true
      else
        false
      end
    else
      @found = false
    end
    render :layout => false
  end
  
  def send_composed
    if params[:message][:reciever].blank?
      flash[:error] = "Fill in a reciever name."
      redirect_to :action => 'compose'
    else

      @reciever = User.find(:first, :conditions => ["login = ?", params[:message][:reciever]])
      unless @reciever
        flash[:error] = "Reciever '#{params[:message][:reciever]}' does not exist."
        redirect_to :action => 'compose'
      else
        reciever_count = Inbox.count(:all, :conditions => ["reciever = ?", @reciever.id]) +
                         Outbox.count(:all, :conditions => ["sender = ?", @reciever.id])
        sender_count = Inbox.count(:all, :conditions => ["reciever = ?", current_user.id]) +
                       Outbox.count(:all, :conditions => ["sender = ?", current_user.id])
        if reciever_count > 500
          flash[:error] = "Sorry. The mailbox of <strong>#{@reciever.login}</strong> is full."
          redirect_to :action => 'compose', :id => current_user.id
        end
        if sender_count > 500
          flash[:error] = "Your mailbox is full. You have to delete massages, before you can send or recieve new ones."
          redirect_to inbox_index_path(current_user)
        end
        
        @message = Message.new(:subject => params[:message][:subject], :text => params[:message][:text])
        
        ActiveRecord::Base.transaction do
          if params[:save_to_outbox]
            ob = Outbox.new(:subject => params[:message][:subject], :text => params[:message][:text])
            ob.reciever = @reciever
            ob.sender = current_user
            ob.save
          end
          ib = Inbox.new(:subject => params[:message][:subject], :text => params[:message][:text])
          ib.sender = current_user
          ib.reciever = @reciever
          
          if ib.save
            flash[:notice] = 'Delivery was successful.'
            redirect_to(inbox_index_path(current_user))
          else
            render :action => "compose"
          end
        end
      end
    end

  end
  

  private
  
  def find_user
    user_id = params[:user_id]
    return(redirect_to(users_url)) unless user_id
    @user = User.find(user_id)
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This user isn`t in the databse. It might have been removed."
        redirect_to users_path
  end
  
end
