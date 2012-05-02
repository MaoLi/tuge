class AccountsController < ApplicationController

  layout 'simple'

	def register
		@user = User.new
	    respond_to do |format|
	      format.html # index.html.erb
	      format.json { render json: @user }
	    end
	end

	def create
		"hello"
	end

	def login
		"hello"
	end

	def logout
	end

end