require 'rest-client'

module NlimsService
  $configs	= YAML.load_file("#{Rails.root}/config/nlims_connection.yml")
  $check_token_url	= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/check_token_validity/"
  $re_authenticate_user_url	= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/re_authenticate/"
  $create_order_url	= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/create_order/"
  $update_test	= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/update_test/"
  $update_specimen	= "#{$configs['nlims_controller_ip']}/api/#{$configs['nlims_api_version']}/update_order/"

  def self.check_token_validity
    token = File.read("#{Rails.root}/tmp/nlims_token")

    res = JSON.parse(RestClient.get($check_token_url + token.to_s, content_type: 'application/json'))
    if res['error'] == false
      true
    else
      res['message']
    end
  end

  def self.re_authenticate_user
    username = $configs['nlims_custome_username']
    password = $configs['nlims_custome_password']

    res = JSON.parse(RestClient.get($re_authenticate_user_url + username + '/' + password,
                                    content_type: 'application/json'))

    if res['error'] == false
      token = res['data']['token']
      File.open("#{Rails.root}/tmp/nlims_token", 'w') do |f|
        f.write(token)
      end
      true
    else
      res['message']
    end
  end

  def self.create_order(params)
    token = File.read("#{Rails.root}/tmp/nlims_token")
    res = JSON.parse(RestClient.post($create_order_url + token.to_s, params, content_type: 'application/json'))

    if res['error'] == false
      [res['data']['tracking_number'], true]
    else
      [res['message'], false]
    end
  end

  def self.update_test(params)
    _token = File.read("#{Rails.root}/tmp/nlims_token")
    headers = {
      content_type: 'application/json',
      token: _token
    }
    res = JSON.parse(RestClient.post($update_test, params, headers))

    if res['error'] == false
      true
    else
      res['message']
    end
  end

  def self.update_specimen(params)
    _token = File.read("#{Rails.root}/tmp/nlims_token")
    headers = {
      content_type: 'application/json',
      token: _token
    }

    res = JSON.parse(RestClient.post($update_specimen, params, headers))

    if res['error'] == false
      true
    else
      res['message']
    end
  end

  def self.create_local_tracking_number
    configs = YAML.load_file "#{Rails.root}/config/application.yml"
    site_code = configs['facility_code']
    file_x = AccessionNumberTracker.last
    file = if file_x.nil?
             AccessionNumberTracker.create(day: Date.today.strftime('%Y%m%d'), acc_num_count: 780)
             {
               "#{Date.today.strftime('%Y%m%d')}" => 780
             }
           else
             {
               file_x.day => file_x.acc_num_count
             }
           end
    todate = Time.now.strftime('%Y%m%d')
    year = Time.now.strftime('%Y%m%d').to_s.slice(2..3)
    month = Time.now.strftime('%m')
    day = Time.now.strftime('%d')
    key = file.keys
    if todate > key[0]
      fi = {}
      fi[todate] = 1
      AccessionNumberTracker.create(day: todate, acc_num_count: 1)
      value = '001'
      tracking_number = 'X' + site_code + year.to_s + get_month(month).to_s + get_day(day).to_s + value.to_s
    else
      counter = file[todate]
      value = if counter.to_s.length == 1
                '00' + counter.to_s
              elsif counter.to_s.length == 2
                '0' + counter.to_s
              else
                begin
                  counter.to_s
                rescue StandardError
                  '001'
                end
              end
      tracking_number = 'X' + site_code + year.to_s + get_month(month).to_s + get_day(day).to_s + value.to_s

    end
    tracking_number
  end

  def self.prepare_next_tracking_number
    file_x = AccessionNumberTracker.last
    todate = Time.now.strftime('%Y%m%d')
    AccessionNumberTracker.create(day: todate, acc_num_count: file_x.acc_num_count + 1)
  end

  def self.get_month(month)
    case month

    when '01'
      '1'
    when '02'
      '2'
    when '03'
      '3'
    when '04'
      '4'
    when '05'
      '5'
    when '06'
      '6'
    when '07'
      '7'
    when '08'
      '8'
    when '09'
      '9'
    when '10'
      'A'
    when '11'
      'B'
    when '12'
      'C'
    end
  end

  def self.get_day(day)
    case day

    when '01'
      '1'
    when '02'
      '2'
    when '03'
      '3'
    when '04'
      '4'
    when '05'
      '5'
    when '06'
      '6'
    when '07'
      '7'
    when '08'
      '8'
    when '09'
      '9'
    when '10'
      'A'
    when '11'
      'B'
    when '12'
      'C'
    when '13'
      'E'
    when '14'
      'F'
    when '15'
      'G'
    when '16'
      'H'
    when '17'
      'Y'
    when '18'
      'J'
    when '19'
      'K'
    when '20'
      'Z'
    when '21'
      'M'
    when '22'
      'N'
    when '23'
      'O'
    when '24'
      'P'
    when '25'
      'Q'
    when '26'
      'R'
    when '27'
      'S'
    when '28'
      'T'
    when '29'
      'V'
    when '30'
      'W'
    when '31'
      'X'
    end
  end
end
