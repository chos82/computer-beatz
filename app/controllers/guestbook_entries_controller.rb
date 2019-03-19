class GuestbookEntriesController < ApplicationController
  include ActionController::Caching
  
  before_filter :login_required
  
  def create
    if logged_in?
    @guestbook_entry = GuestbookEntry.new(params[:guestbook_entry])
    @guestbook_entry.gb_sender = current_user
    @user = User.find(params[:user_id])
    @guestbook_entry.gb_reciever = @user

    respond_to do |format|
      if @guestbook_entry.save
        flash[:notice] = 'Gestbook entry was successfully created.'
        format.html { redirect_to(:controller => 'users', :action => 'show', :id => @user) }
        format.xml  { render :xml => @guestbook_entry, :status => :created, :location => @guestbook_entry }
      else
        format.html { render :controller => 'users', :action => "show", :id => @user }
        format.xml  { render :xml => @guestbook_entry.errors, :status => :unprocessable_entity }
      end
    end
    end
  end
  
  def destroy
    @user = User.find(params[:user_id])
    if current_user == @user
      @entry = GuestbookEntry.find(params[:id])
      @entry.destroy
      flash[:notice] = 'Guestbook entry was successfully destroyed.'
      redirect_to @user
    else
      redirect_to users_url
    end
    rescue ActiveRecord::RecordNotFound
        flash[:notice] = "This message isn`t in the databse. It might have been removed."
        redirect_to @user
  end
  
end
