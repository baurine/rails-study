class MicropostsController < ApplicationController
  def index
    user = User.find(params[:user_id])
    # paginate
    @microposts = paginate(user.microposts)
    # add paginate meta
    render json: @microposts, meta: paginate_meta(@microposts)
  end
end
