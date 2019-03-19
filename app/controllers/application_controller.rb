# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include AuthenticatedSystem
  include ExceptionNotifiable
  
  #def default_url_options(options={})
  #  { :page => 1 }
  #end

  session :session_key => '_computer-beatz_session_id'
  
  #TODO: Block users
  #TODO: common friends
  #TODO: attr_accessors -> prevent crafted forms
  #TODO: attribution_rules, projects_info
  #TODO: use Prototype Event constants for keybord evens
  #TODO: remember your admin email: chris@computer-beatz.net
  #TODO: application.js contains ':3000' port in window.open
  
  helper :all # include all helpers, all the time

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  #protect_from_forgery  :secret => '292a5cacaf7b7ad00d42bda423e8163c'
  
  # See ActionController::Base for details 
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password"). 
  # filter_parameter_logging :password
  
  #def check_authentication
  #  unless session[:user]
  #    session[:intended_action] = action_name
  #    session[:intended_controller] = controller_path #url_for(:only_path => true) #controller_name
  #    session[:intended_id] = params[:id]
  #    flash[:notice] = "You have to be signed in to access this action."
  #    redirect_to login_path
  #  end
  #end
  
  def show_page?(user, option)
    if logged_in? && user == current_user
       return true
    elsif option == 'privat'
      return false
    elsif option == 'friends'
      return true if logged_in? && current_user.is_mutual_friends_with?(user)
      return false
    elsif option == 'users'
      return logged_in?
    elsif option == 'public'
      return true
    else
      false
    end
  end
  
end
