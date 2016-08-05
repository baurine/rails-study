class UserSerializer < ActiveModel::Serializer
  attributes :id, :name, :email, :activated, :admin
end
