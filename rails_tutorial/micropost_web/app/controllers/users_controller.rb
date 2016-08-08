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

  # PATCH / PUT

  # DELETE
end
