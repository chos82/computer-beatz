class Admin::UsersController < ApplicationController
  layout 'admin'
  
  before_filter :check_administrator_role
  
  def index
    @users = User.paginate(:all, :page => params[:page], :order => 'login')
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
    end
  end
  
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end
  
  def edit
    @user = User.find(params[:id])
    @roles = Role.find(:all)
  end
  
  def destroy
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, false)
      flash[:notice] = "User disabled"
    else
      flash[:error] = "There was a problem disabling this user."
    end
    redirect_to :action => 'index'
  end

  def enable
    @user = User.find(params[:id])
    if @user.update_attribute(:enabled, true)
      flash[:notice] = "User enabled"
    else
      flash[:error] = "There was a problem enabling this user."
    end
      redirect_to :action => 'index'
  end
  
  def remove
    @user = User.find(params[:id])
    if @user.destroy
      flash[:notice] = "User was removed from DB"
    else
      flash[:error] = "There was a problem removing this user."
    end
    redirect_to :action => 'index'
  end
  
  def search_by_email
    @users = User.paginate(:all, :page => params[:page], :conditions => ["email LIKE ?", '%' + params[:search][:email] + '%'])
    render :action => 'index'
  end
  
  def search_by_login
    @users = User.paginate(:all, :page => params[:page], :conditions => ["login LIKE ?", '%' + params[:search][:login] + '%'])
    render :action => 'index'
  end


end
