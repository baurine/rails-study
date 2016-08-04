class User < ApplicationRecord

  before_create :generate_auth_token

  def generate_auth_token
    loop do
      self.auth_token = SecureRandom.base64(64).tr('+/=', 'Qrt')
      break unless User.exists?(auth_token: auth_token)
    end
  end

  def reset_auth_token
    generate_auth_token
    save
  end

end
