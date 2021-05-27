require "rest-client"

module NlimsService

	$configs 					= YAML.load_file("#{Rails.root}/config/nlims_connection.yml")
	$check_token_url 			= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/check_token_validity/"
	$re_authenticate_user_url 	= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/re_authenticate/"
	$create_order_url		 	= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/create_order/"
	$update_test 				= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/update_test/"
	$update_specimen			= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/update_order/"

	def self.check_token_validity
		token = File.read("#{Rails.root}/tmp/nlims_token")
	
		res = JSON.parse(RestClient.get($check_token_url + token.to_s, :content_type => "application/json"))		
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


	def self.create_order(params)
		token = File.read("#{Rails.root}/tmp/nlims_token")
		res = JSON.parse(RestClient.post($create_order_url + token.to_s ,params, :content_type => 'application/json'))
		
		if res['error'] == false
			return [res['data']['tracking_number'],true]
		else
			return  [res['message'],false]
		end

	end

	def self.update_test(params)
		_token = File.read("#{Rails.root}/tmp/nlims_token")
		headers = {
      		content_type: "application/json",
      		token: _token
		}
		res = JSON.parse(RestClient.post($update_test,params, headers))

		if res['error'] == false
			return true
		else
			return  res['message']
		end

	end


	def self.update_specimen(params)
		_token = File.read("#{Rails.root}/tmp/nlims_token")
		headers = {
      		content_type: "application/json",
      		token: _token
		}  
	
		res = JSON.parse(RestClient.post($update_specimen,params,headers))

		if res['error'] == false
			return true
		else
			return  res['message']
		end

	end


	def self.create_local_tracking_number
		configs = YAML.load_file "#{Rails.root}/config/application.yml"
		site_code = configs['facility_code']
		file = JSON.parse(File.read("#{Rails.root}/public/tracker.json"))
		todate = Time.now.strftime("%Y%m%d")
		year = Time.now.strftime("%Y%m%d").to_s.slice(2..3)
		month = Time.now.strftime("%m")
		day = Time.now.strftime("%d")
	
		key = file.keys
		
		if todate > key[0]

			fi = {}
			fi[todate] = 1
			File.open("#{Rails.root}/public/tracker.json", 'w') {|f|
					
	    	     	f.write(fi.to_json) } 

	    	 value =  "001"
	    	 tracking_number = "X" + site_code + year.to_s +  get_month(month).to_s +  get_day(day).to_s + value.to_s
			
		else
			counter = file[todate]

			if counter.to_s.length == 1
				
				value = "00" + counter.to_s
			elsif counter.to_s.length == 2
				
				value = "0" + counter.to_s
			else
				value = counter.to_s rescue "001"
			end
			

			tracking_number = "X" + site_code + year.to_s +  get_month(month).to_s +  get_day(day).to_s + value.to_s
			
		end
		return tracking_number
	end

	def self.prepare_next_tracking_number
			file = JSON.parse(File.read("#{Rails.root}/public/tracker.json"))
			todate = Time.now.strftime("%Y%m%d")
				
			counter = file[todate]
			counter = counter.to_i + 1
			fi = {}
			fi[todate] = counter
			File.open("#{Rails.root}/public/tracker.json", 'w') {|f|
					
	    	     	f.write(fi.to_json) } 	
	end

	def self.get_month(month)
		
		case month

			when "01"
				return "1"
			when "02"
				return "2"
			when "03"
				return "3"
			when "04"
				return "4"
			when "05"
				return "5"
			when "06"
				return "6"
			when "07"
				return "7"
			when "08"
				return "8"
			when "09"
				return "9"
			when "10"
				return "A"
			when "11"
				return "B"
			when "12"
				return "C"
			end

	end

	def self.get_day(day)

		case day

			when "01"
				return "1"
			when "02"
				return "2"
			when "03"
				return "3"
			when "04"
				return "4"
			when "05"
				return "5"
			when "06"
				return "6"
			when "07"
				return "7"
			when "08"
				return "8"
			when "09"
				return "9"
			when "10"
				return "A"
			when "11"
				return "B"
			when "12"
				return "C"
			when "13"
				return "E"
			when "14"
				return "F"
			when "15"
				return "G"
			when "16"
				return "H"
			when "17"
				return "Y"
			when "18"
				return "J"
			when "19"
				return "K"
			when "20"
				return "Z"
			when "21"
				return "M"
			when "22"
				return "N"
			when "23"
				return "O"
			when "24"
				return "P"
			when "25"
				return "Q"
			when "26"
				return "R"
			when "27"
				return "S"
			when "28"
				return "T"
			when "29"
				return "V"
			when "30"
				return "W"
			when "31"
				return "X"
			end	

	end



end
