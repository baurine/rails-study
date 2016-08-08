class UsersController < ApplicationController
  # GET
  def new
    # debugger
  end

  def show
    @user = User.find(params[:id])
    # debugger
  end

  # POST

  # PATCH / PUT

  # DELETE
end
