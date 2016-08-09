module SessionsHelper
  # 保存登录用户
  def log_in(user)
    session[:user_id] = user.id
    # debugger
  end

  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    !current_user.nil?
    # debugger
  end
end
