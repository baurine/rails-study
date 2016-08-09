class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(email: session_params[:email].downcase)
    if user && user.authenticate(session_params[:password])
      flash[:success] = "Login successfully!"
      redirect_to user
    else
      flash.now[:danger] = "Email and password didn't match!"
      render 'new'
    end
  end

  def destroy
  end

  private
    def session_params
      params.require(:session).permit(:email, :password)
    end
end
