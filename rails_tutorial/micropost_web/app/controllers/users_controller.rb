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

  def edit
    @user = User.find(params[:id])
  end

  # POST
  def create
    @user = User.new(user_params)

    if @user.save
      log_in @user
      flash[:success] = "Welcome to Rails Sample App"
      redirect_to @user
    else
      render 'new'
    end
  end

  # PATCH / PUT
  def update
    @user = User.find(params[:id])
    if @user.update_attributes(user_params)
      flash[:success] = "Update successfully!"
      redirect_to @user
    else
      render 'edit'
    end
  end

  # DELETE

  private
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end
end
