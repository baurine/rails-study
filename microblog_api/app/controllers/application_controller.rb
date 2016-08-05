class ApplicationController < ActionController::API
  include Pundit
  attr_accessor :current_user
  rescue_from Pundit::NotAuthorizedError, with: :deny_access

  def deny_access
    api_error(status: 403)
  end

  def api_error(opts = {})
    render head: :unauthorized, status: opts[:status]
  end

  def unauthenticated!
    api_error(status: 401)
  end

  def authenticate_user!
    token, options = ActionController::HttpAuthentication::Token.token_and_options(request)

    user = User.find_by(email: options[:email])

    if user && ActiveSupport::SecurityUtils.secure_compare(user.auth_token, token)
      self.current_user = user
    else
      unauthenticated!
    end
  end

end
