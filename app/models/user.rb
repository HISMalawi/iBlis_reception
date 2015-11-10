require 'digest/sha1'
require 'digest/sha2'

class User < ActiveRecord::Base
  #default_scope { where(retired: 0) }

  cattr_accessor :current
  cattr_accessor :login_location

  def self.authenticate(username, password)
		return user = self.where(:username => username).first
    if !user.blank?
      user.valid_password?(password) ? user : nil
		end

	end
    
  def encrypted_password
    self.password
  end 

  def valid_password?(password)
    return false if encrypted_password.blank?
    is_valid = Digest::SHA1.hexdigest("#{password}#{salt}") == encrypted_password || encrypt(password, salt) == encrypted_password || Digest::SHA512.hexdigest("#{password}#{salt}") == encrypted_password
  end

  def encrypt(plain, salt)
    encoding = ""
    digest = Digest::SHA1.digest("#{plain}#{salt}") 
    (0..digest.size-1).each{|i| encoding << digest[i].to_s(16) }
    encoding
  end

end
