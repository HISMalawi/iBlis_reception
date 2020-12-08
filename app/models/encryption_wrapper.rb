require 'openssl'
require 'base64'
#Kenneth Kapundi
class EncryptionWrapper

  def initialize(attribute, run_level=0)
		#---------run_level------------		
		#0 default fo object attributes
		#1 to encrypt attribute str
		#2 to decrypt attribute str and return hash

		if run_level == 2
			@attribute = decrypt(attribute)
		elsif run_level == 1
			@attribute = encrypt(attribute)
		elsif run_level == 0
	    @attribute = attribute
		else
			#make it fail
			@attribute = nil
		end
  end

  PASSWORD = File.read("config/key").strip
  CIPHER_METHOD = 'AES-256-CBC'

  def before_save(record)

    if !record.send("#{@attribute}").blank?
      if @attribute == 'name'
        name = record.send("#{@attribute}").strip.split(/\s+/) rescue nil
        f_name = name.length > 0 ? name.first : ""
        l_name = name.length > 1 ? name.last : ""
        record.send("first_name_code=", f_name.soundex)
        record.send("last_name_code=", l_name.soundex)
      end

      if record.has_attribute?("#{@attribute}_code")
        record.send("#{@attribute}_code=", record.send("#{@attribute}").soundex)
      end

      record.send("#{@attribute}=", encrypt(record.send("#{@attribute}"))) unless record.send("#{@attribute}").blank?
    end

  end

  def after_find(record)

    if !record.send("#{@attribute}").blank?
      record.send("#{@attribute}=", decrypt(record.send("#{@attribute}"))) unless record.send("#{@attribute}").blank?
    end
  end
	
	def self.cryptize(str)
		self.new(str, 1).as_json['attribute']
	end

	def self.humanize(str)
		self.new(str, 2).as_json['attribute']
	end

  private
  def encrypt(str)

    if str.length > 40 && !str.strip.match(/\s/)
      return str
    end

    cipher = OpenSSL::Cipher.new(CIPHER_METHOD)
    cipher.encrypt
    iv = OpenSSL::Random.random_bytes(cipher.iv_len)
    cipher.iv = iv
    cipher.key = PASSWORD
    str = iv + str
    data = cipher.update(str) + cipher.final
    Base64.urlsafe_encode64(data)

  end

  def decrypt(str)

    data = Base64.urlsafe_decode64(str) rescue ""
    cipher = OpenSSL::Cipher.new(CIPHER_METHOD)
    if cipher.iv_len-1 < data.length
      cipher.decrypt
      cipher.key = PASSWORD
      cipher.iv = data[0..(cipher.iv_len-1)]
      data_body = data[cipher.iv_len..-1]
      cipher.update(data_body) + cipher.final
    end
  end

end
