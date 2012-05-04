class ApplicationController < ActionController::Base
  protect_from_forgery

  def redirect_back_or_default(default)
    back_url = CGI.unescape(params[:back_url].to_s)
    if !back_url.blank?
      begin
        uri = URI.parse(back_url)
        # do not redirect user to another host or to the login or register page
        if (uri.relative? || (uri.host == request.host)) && !uri.path.match(%r{/(login|accounts/register)})
          redirect_to(back_url)
          return
        end
      rescue URI::InvalidURIError
        # redirect to default
      end
    end
    redirect_to default
    false
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

end
