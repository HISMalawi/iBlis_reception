require "rest-client"


module NlimsService

	$configs 					= YAML.load_file("#{Rails.root}/config/nlims_connection.yml")
	$check_token_url 			= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/check_token_validity"
	$re_authenticate_user_url 	= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/re_authenticate/"
	$create_order_url		 	= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/create_order"	
	$update_order				= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/update_order"
	$add_test 					= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/add_test"


	def self.check_token_validity
		token_ = File.read("#{Rails.root}/tmp/nlims_token")

		headers = { 
			content_type: 'application/json', 
			token: token_
		}

		res = JSON.parse(RestClient.get($check_token_url, headers))		

		if res['error'] == false
			return true
		else
			return res['message']
		end
	end

	def self.re_authenticate_user
		username = $configs['nlims_custome_username']
		password = $configs['nlims_custome_password']

		res = JSON.parse(RestClient.get($re_authenticate_user_url + username + "/" + password, :content_type => "application/json"))

		if res['error'] == false
			token = res['data']['token']
			File.open("#{Rails.root}/tmp/nlims_token", "w") { |f|
				f.write(token)
			}
			return true
		else	
			return res['message']
		end
	end

	def self.create_order(order_data)
		
		token_ = File.read("#{Rails.root}/tmp/nlims_token")
		headers = {
			content_type: 'application/json',
			token: token_
		}

		
		res = JSON.parse(RestClient.post($create_order_url,order_data, headers ))
		if res['error'] == false
			return [res['data']['tracking_number'],true]
		else
			return  [res['message'],false]
		end
	end

	def self.update_order(params)
		token_ = File.read("#{Rails.root}/tmp/nlims_token")
		headers = {
			content_type: 'application/json',
			token: token_
		}
		
		res =  JSON.parse(RestClient.post($update_order,params.to_json, headers ))		
		if res['error'] == true
			return true
		else
			return res['message']
		end	
	end

	def self.add_test(params)
		token_ = File.read("#{Rails.root}/tmp/nlims_token")
		headers = {
			content_type: 'application/json',
			token: token_
		}
		res =  JSON.parse(RestClient.post($add_test,params.to_json, headers ))

		if res['error'] == true
			return true
		else
			return res['message']
		end	
	end
end
