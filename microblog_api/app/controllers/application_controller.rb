class ApplicationController < ActionController::API
  attr_accessor :current_user

  def api_error(opts = {})
    render head: :unauthorized, status: opts[:status]
  end
end
