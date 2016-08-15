class SessionsController < ApplicationController
  # GET
  def new
  end

  # POST
  def create
    user = User.find_by(email: session_params[:email].downcase)
    if user && user.authenticate(session_params[:password])
      flash[:success] = "Login successfully!"
      log_in user
      session_params[:remember_me] == '1' ? remember(user) : forget(user)
      # remember user
      # redirect_to user
      redirect_back_or user
    else
      flash.now[:danger] = "Email and password didn't match!"
      render 'new'
    end
  end

  # DELETE
  def destroy
    log_out if logged_in?
    redirect_to root_url
  end

  private
    def session_params
      params.require(:session).permit(:email, :password, :remember_me)
    end
end
