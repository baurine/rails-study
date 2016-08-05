class SessionSerializer < ActiveModel::Serializer
  attributes :id, :name, :admin, :token

  def token
    object.auth_token
  end
end
