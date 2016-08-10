class MicropostsController < ApplicationController
  before_action :logged_in_user, only: [:create, :destroy]

  # POST
  def create
  end

  # DELETE
  def destroy
  end
end
