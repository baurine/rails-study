class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper

  # def hello
  #   render html: "Hello~!"
  # end

  private
    def logged_in_user
      unless logged_in?
        store_location
        flash[:danger] = "Please login first!"
        redirect_to login_url
      end
    end

end
