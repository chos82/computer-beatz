# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  layout 'application'
  before_filter :login_required, :only => :destroy
  before_filter :not_logged_in_required, :only => [:new, :create]
  
  # render new.rhtml
  def new
  end

  def create
    password_authentication(params[:login], params[:password])
  end

  def destroy
    self.current_user.forget_me if logged_in?
    cookies.delete :auth_token
    reset_session
    flash[:notice] = "You have been logged out."
    redirect_back_or_default('/')
  end
  
  protected
 
  # Updated 2/20/08
  def password_authentication(login, password)
    user = User.authenticate(login, password)
    if user == nil
      failed_login("Your username or password is incorrect.")
    elsif user.activated_at.blank?  
      failed_login("Your account is not active, please check your email for the activation code.")
    elsif user.enabled == false
      failed_login("Your account has been disabled. If you think this happend by accident, please contact.")
    else
      self.current_user = user
      successful_login
    end
  end


  private

  def failed_login(message)
    flash[:error] = message
    render :action => 'new'
  end

  def successful_login
    if params[:remember_me] == "1"
      self.current_user.remember_me
      cookies[:auth_token] = { :value => self.current_user.remember_token , :expires => self.current_user.remember_token_expires_at }
    end
    current_user.last_login = Time.now
    current_user.save
    flash[:notice] = "Logged in successfully."
    return_to = session[:return_to]
    if return_to.nil?
      redirect_to user_path(self.current_user)
    else
      redirect_to return_to
    end
  end

end
