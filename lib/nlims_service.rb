require "rest-client"

module NlimsService

	$configs 					= YAML.load_file("#{Rails.root}/config/nlims_connection.yml")
	$check_token_url 			= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/check_token_validity/"
	$re_authenticate_user_url 	= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/re_authenticate/"
	$create_order_url		 	= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/create_order/"
	$update_test 				= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/update_test/"

	def self.check_token_validity
		token = File.read("#{Rails.root}/tmp/nlims_token")
	
		res = JSON.parse(RestClient.get($check_token_url + token.to_s, :content_type => "application/json"))		
		if res['error'] == false
			return true
		else
			return false
		end

	end


	def self.re_authenticate_user
		username = $configs['nlims_custome_username']
		password = $configs['nlims_custome_password']

		res = JSON.parse(RestClient.get($check_token_url + username + "/" + password, :content_type => "application/json"))
		
		if res['error'] == false
			token = res['data']['token']
			File.open("#{Rails.root}/tmp/nlims_token", "w") { |f|
				f.write(token)
			}
			return true
		else	
			return false
		end

	end


	def self.create_order(params)
		token = File.read("#{Rails.root}/tmp/nlims_token")
		res = JSON.parse(RestClient.post($create_order_url + token.to_s ,params, :content_type => 'application/json'))

		if res['error'] == false
			return res['data']['tracking_number']
		else
			return false
		end

	end



	def self.update_test(params)
		token = File.read("#{Rails.root}/tmp/nlims_token")
		res = JSON.parse(RestClient.post($update_test + token.to_s ,params, :content_type => 'application/json'))

		if res['error'] == false
			return true
		else
			return false
		end

	end




end
