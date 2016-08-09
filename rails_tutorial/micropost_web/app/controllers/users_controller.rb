class UsersController < ApplicationController
  # GET
  def new
    # debugger
    @user = User.new
  end

  def show
    @user = User.find(params[:id])
    # debugger
  end

  # POST
  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user
    else
      render 'new'
    end
  end

  # PATCH / PUT

  # DELETE

  private
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end
