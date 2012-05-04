class AccountsController < ApplicationController

  layout 'simple'

	def register
	  if request.get?
		  @user = User.new
	    respond_to do |format|
	      format.html # index.html.erb
	      format.json { render json: @user }
	    end
	  elsif request.post?
	  	@user = User.new(params[:user])

	  	if @user.save
	  		flash[:notice] = "create sucessfully"
	  		redirect_to :action => :login
	  	else
	  		#flash[:error] = "test"
	  		render :register
	  	end	
	  end
	end

  def login
    if request.get?
      logout_user
    else
      authenticate_user
    end
  end

  def logout
    flash[:notice]  = "Successfully logged out"
    self.current_user.forget_me
    self.current_user = nil
    session[:user_id] = nil
    cookies.delete :auth_token
    #cookies.delete :typo_user_profile
    redirect_to :action => 'login'
  end

	private 

	def authenticate_user
    user = User.try_to_login(params[:username], params[:password])

    if user.nil? || user.is_a?(Integer)
      invalid_credentials user
    else
      # Valid user
      successful_authentication(user)
    end
	end

  def invalid_credentials(error_id)
    err = ''
    error_info = l(:notice_account_invalid_creditentials)
    case error_id
      when -1
        err= 'inactive'
        error_info = l(:notice_account_inactive_creditentials)
    end
    logger.warn "Failed login for #{err} '#{params[:username]}' from #{request.remote_ip} at #{Time.now.utc}"
    flash.now[:error] = error_info
  end

  def successful_authentication(user)
    # Valid user
    self.logged_user = user
    # generate a key and set cookie if autologin
    if params[:remember_me] #&& Setting.autologin?
      set_autologin_cookie(user)
    end

    redirect_back_or_default :controller => :orders, :action => :index
  end

  def set_autologin_cookie(user)

  end

	def logged_in?
	  current_user != :false
	end

	def current_user
	  @current_user ||= (login_from_session || login_from_basic_auth || login_from_cookie || :false)
	end

	def current_user=(new_user)
	  session[:user] = (new_user.nil? || new_user.is_a?(Symbol)) ? nil : new_user.id
	  @current_user = new_user
	end

  def login_from_session
    self.current_user = User.find_by_id(session[:user]) if session[:user]
  end
=begin
  def login_from_basic_auth
    email, passwd = get_auth_data
    self.current_user = User.authenticate(email, passwd) if email && passwd
  end
=end
  # Called from #current_user.  Finaly, attempt to login by an expiring token in the cookie.
  def login_from_cookie
    user = cookies[:auth_token] && User.find_by_remember_token(cookies[:auth_token])
    if user && user.remember_token?
      user.remember_me
      cookies[:auth_token] = { :value => user.remember_token, :expires => user.remember_token_expires_at }
      self.current_user = user
    end
  end

end