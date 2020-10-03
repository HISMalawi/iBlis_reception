
namespace :nlims do
  desc "TODO"
  task authenticate: :environment do
  	config = YAML.load_file("#{Rails.root}/config/application.yml")
    configs = YAML.load_file("#{Rails.root}/config/nlims_connection.yml")
  	nlims_url = configs['nlims_controller_ip'] + "/api/v1/authenticate/" +  configs['nlims_default_username'] + "/" + configs['nlims_default_password']
   

  	res =  JSON.parse(RestClient.get(nlims_url, :content_type => 'application/json'))

    if res['error'] == false
      token = res['data']['token']
      File.open("#{Rails.root}/tmp/nlims_token",'w') { |f|
        f.write(token)
      }

      puts res['message'] + "!  create account now"
    else
      puts res
    end

  end



  desc "TODO"
  task create_account: :environment do
    config = YAML.load_file("#{Rails.root}/config/application.yml")
    configs = YAML.load_file("#{Rails.root}/config/nlims_connection.yml")
    token = File.read("#{Rails.root}/tmp/nlims_token")
    nlims_url = configs['nlims_controller_ip'] + "/api/v1/create_user"
    #raise nlims_url.inspect
      headers = {
        content_type:  'application/json',
        token: token
      }
    account_details = {
            "partner": configs['partner_name'],
            "app_name": configs['app_name'],
            "location": "Lilongwe",
            "password": configs['nlims_custome_password'],
            "username": configs['nlims_custome_username']
    }   

    res =  JSON.parse(RestClient.post(nlims_url, account_details,headers))
     
        if res['error'] == false
            File.open("#{Rails.root}/tmp/nlims_token",'w') {|f|
              f.write(res['data']['token'].to_s)
            }
            puts res['message'] +"! can now access nlims resources"

        else

          puts res['message']  
        end 


  end

end
