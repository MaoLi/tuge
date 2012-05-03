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
	  		flash[:notice] = l(:successful_create_user)
	  		redirect_to :login
	  	else
	  		flash[:error] = "test"
	  		redirect_to :action => :register
	  	end	
	  end
	end



	def login
		"hello"
	end

	def logout
	end

end