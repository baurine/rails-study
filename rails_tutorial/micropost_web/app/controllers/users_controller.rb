class UsersController < ApplicationController
  before_action :find_user,      only: [:show, :edit, :update, :destroy]
  before_action :logged_in_user, only: [:index, :edit, :update, :destroy]
  before_action :correct_user,   only: [:edit, :update]
  before_action :check_admin,    only: [:destroy]

  # GET
  def index
    # @users = User.all
    @users = User.paginate(page: params[:page])
  end

  def new
    @user = User.new
  end

  def show
    @microposts = @user.microposts.paginate(page: params[:page])
  end

  def edit
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
    if @user.update_attributes(user_params)
      flash[:success] = "Update successfully!"
      redirect_to @user
    else
      render 'edit'
    end
  end

  # DELETE
  def destroy
    @user.destroy
    flash[:success] = "#{@user.name} has already deleted."
    redirect_to users_url
  end

  private
    def user_params
      params.require(:user).permit(:name, :email, :password, :password_confirmation)
    end

    def find_user
      @user = User.find(params[:id])
    end

    # moved to application_controller
    # def logged_in_user
    #   unless logged_in?
    #     store_location
    #     flash[:danger] = "Please login first!"
    #     redirect_to login_url
    #   end
    # end

    def correct_user
      redirect_to(root_url) unless current_user?(@user)
    end

    def check_admin
      redirect_to(root_url) unless current_user.admin?
    end
end
