class SessionsController < ApplicationController

  # POST
  def create
    @user = User.find_by(email: create_params[:email])
    if @user && @user.authenticate(create_params[:password])
      self.current_user = @user
      render json: current_user, serializer: SessionSerializer
    else
      api_error(status: 401)
    end
  end

  private
    def create_params
      # where is params from? why it has no @ or @@ prefix?
      # it is a method
      params.require(:user).permit(:email, :password)
    end
end
