=begin
	By Kenneth Kapundi
	13-Jun-2016

	DESC:
		This service acts as a wrapper for all DDE2 interactions 
		between the application and the DDE2 proxy at a site
		This include:	
			A. User creation and authentication
			B. Creating new patient to DDE
			C. Updating already existing patient to DDE2
			D. Handling duplicates in DDE2
			E. Any other DDE2 related functionality to arise
=end

require 'rest-client'

module DDE2Service

  def self.dde2_configs
    YAML.load_file("#{Rails.root}/config/dde_connection.yml")[Rails.env]
  end

  def self.dde2_url
    dde2_configs = self.dde2_configs
    protocol = dde2_configs['secure_connection'].to_s == 'true' ? 'https' : 'http'
    "#{protocol}://#{dde2_configs['dde_server']}"
  end

  def self.dde2_url_with_auth
    dde2_configs = self.dde2_configs
    protocol = dde2_configs['secure_connection'].to_s == 'true' ? 'https' : 'http'
    "#{protocol}://#{dde2_configs['dde_username']}:#{dde2_configs['dde_password']}@#{dde2_configs['dde_server']}"
  end

  def self.authenticate
    dde2_configs = self.dde2_configs
    url = "#{self.dde2_url}/v1/authenticate"

    res = JSON.parse(RestClient.post(url, {'username' => dde2_configs['dde_username'],
                                           'password' => dde2_configs['dde_password']}.to_json, :content_type => 'application/json'))
    token = nil
    if (res['status'] && res['status'] == 200)
      token = res['data']['token']
    end

    File.open("#{Rails.root}/tmp/token", 'w') {|f| f.write(token) } if token.present?
    token
  end

  def self.authenticate_by_admin
    dde2_configs = self.dde2_configs
    url = "#{self.dde2_url}/v1/authenticate"

    params = {'username' => 'admin', 'password' => 'admin'}

    res = JSON.parse(RestClient.post(url, params.to_json, :content_type => 'application/json'))
    token = nil
    if (res['status'] && res['status'] == 200)
      token = res['data']['token']
    end

    token
  end

  def self.add_user(token)
    dde2_configs = self.dde2_configs
    url = "#{self.dde2_url}/v1/add_user"
    url = url.gsub(/\/\//, "//admin:admin@")

    response = RestClient::Request.execute(
        method: :put,
        url:    url,
        payload:{
            "username" => dde2_configs["dde_username"],  "password" => dde2_configs["dde_password"],
            "application" => dde2_configs["application_name"], "site_code" => dde2_configs["site_code"],
            "description" => "AnteNatal Clinic"
        }.to_json,
        headers: {:content_type => 'application/json'}
    )

    if response['status'] == 201
      puts "DDE2 user created successfully"
      return JSON.parse(response)['data']
    else
      puts "Failed with response code #{response['status']}"
      return false
    end
  end

  def self.token
    self.validate_token(File.read("#{Rails.root}/tmp/token"))
  end

  def self.validate_token(token)
    url = "#{self.dde2_url}/v1/authenticated/#{token}"
    response = nil
    response = JSON.parse(RestClient.get(url)) rescue nil if !token.blank?

    if !response.blank? && response['status'] == 200
      return token
    else
      return self.authenticate
    end
  end

  def self.format_params(params, date)
    gender = (params['person']['gender'].match(/F/i)) ? "Female" : "Male"

    birthdate = nil
    if params['person']['age_estimate'].present?
      birthdate = Date.new(date.to_date.year - params['person']['age_estimate'].to_i, 7, 1).strftime("%Y-%m-%d")
    else
      params['person']['birth_month'] = params['person']['birth_month'].rjust(2, '0')
      params['person']['birth_day'] = params['person']['birth_day'].rjust(2, '0')
      birthdate = "#{params['person']['birth_year']}-#{params['person']['birth_month']}-#{params['person']['birth_day']}"
    end

    citizenship = [
                    params['person']['citizenship'],
                    params['person']['race']
                  ].delete_if{|d| d.blank?}.last
    country_of_residence = District.find_by_name(params['person']['addresses']['state_province']).blank? ?
        params['person']['addresses']['state_province'] : nil

    result = {
        "family_name"=> params['person']['names']['given_name'],
        "given_name"=> params['person']['names']['family_name'],
        "middle_name"=> params['person']['names']['given_name'],
        "gender"=> gender,
        "attributes"=> {
          "occupation"=> params['person']['occupation'],
          "cell_phone_number"=> params['person']['cell_phone_number'],
          "citizenship" => citizenship,
          "country_of_residence" => country_of_residence
        },
        "birthdate"=> birthdate,
        "identifiers"=> {
        },
        "birthdate_estimated"=> (params['person']['age_estimate'].present?),
        "current_residence"=> params['person']['addresses']['address1'],
        "current_village"=> params['person']['addresses']['city_village'],
        "current_ta"=> params['person']['addresses']['neighborhood_cell'],
        "current_district"=> params['person']['addresses']['state_province'],
        "home_village"=> params['person']['addresses']['neighborhood_cell'],
        "home_ta"=> params['person']['addresses']['county_district'],
        "home_district"=> params['person']['addresses']['address2'],
        "token"=> "fdc2d5b14f7711e7af26d07e358088a6"
    }

    result['attributes'].each do |k, v|
      if v.blank?
        result['attributes'].delete(k)
      end
    end

    result['identifiers'].each do |k, v|
      if v.blank? || v.match(/^N\/A$|^null$|^undefined$|^nil$/i)
        result['identifiers'].delete(k)
      end
    end

    if !result['attributes']['country_of_residence'].blank? && !result['attributes']['country_of_residence'].match(/Malawi/i)
      result['current_district'] = 'Other'
      result['current_ta'] = 'Other'
      result['current_village'] = 'Other'
    end

    if !result['attributes']['citizenship'].blank? && !result['attributes']['citizenship'].match(/Malawi/i)
      result['home_district'] = 'Other'
      result['home_ta'] = 'Other'
      result['home_village'] = 'Other'
    end

    result
  end

  def self.is_valid?(params)
    valid = true
    ['family_name', 'given_name', 'gender', 'birthdate', 'birthdate_estimated', 'home_district', 'token'].each do |key|
      if params[key].blank? || params[key].to_s.strip.match(/^N\/A$|^null$|^undefined$|^nil$/i)
        valid = false
      end
    end

    if valid && !params['birthdate'].match(/\d{4}-\d{1,2}-\d{1,2}/)
      valid = false
    end

    if valid && !['Female', 'Male'].include?(params['gender'])
      valid = false
    end

    valid
  end

  def self.dde2_url_with_auth
    dde2_configs = self.dde2_configs
    protocol = dde2_configs['secure_connection'].to_s == 'true' ? 'https' : 'http'
    "#{protocol}://#{dde2_configs['dde_username']}:#{dde2_configs['dde_password']}@#{dde2_configs['dde_server']}"
  end

  def self.search_from_dde2(params)
    url = "#{self.dde2_url_with_auth}/v1/search_by_name_and_gender"
    response = RestClient::Request.execute(
        method: :post,
        url:    url,
        payload: {'given_name' => params['given_name'],
                  'family_name' => params['family_name'],
                  'gender' => ({"1" => "Female", "0" => "Male"}[params['gender']] || params['gender'])
                 }.to_json,
        headers: {:content_type => 'application/json'}
    )

    if !response.blank? || response['status'] == 200
      return JSON.parse(response)['data']['hits']
    else
      return false
    end
  end

  def self.search_by_identifier(npid)

    url = "#{self.dde2_url_with_auth}/v1/search_by_identifier/#{npid}/#{self.token}"
    response = JSON.parse(RestClient.get(url))

    if response.present? && response['status']
      return response['data']['hits']
    else
      return false
    end
  end

end
