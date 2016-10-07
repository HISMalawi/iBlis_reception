require 'digest/sha1'
require 'digest/sha2'

class User < BlisConnection
  #default_scope { where(retired: 0) }

  cattr_accessor :current
  cattr_accessor :login_location

  def self.authenticate(username, password)

    user = User.where(:username => username).first

    if user && user.valid_password?(password)
      user
    else
      nil
    end
  end

  def valid_password?(password)
    laravel_pass = self.password
    ruby_pass = BCrypt::Password.new laravel_pass.gsub('$2y$','$2a$')
    ruby_pass.is_password? password
  end

end
