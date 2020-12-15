
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
    #nlims_url = configs['nlims_controller_ip'] + "/api/v1/create"
    nlims_url = configs['nlims_controller_ip'] + "/api/v1/create_user"
    #raise nlims_url.inspect
      headers = {
        content_type:  'application/json',
        token: token
      }
    
	account_details = {
            "partner" => configs['partner_name'],
            "app_name" => configs['app_name'],
            "location" => "Lilongwe",
            "password" => configs['nlims_custome_password'],
            "username" => configs['nlims_custome_username']
    }   

    res =  JSON.parse(RestClient.post(nlims_url,account_details,headers))
    #res =  JSON.parse(RestClient.get(nlims_url,headers))
    # puts res
        if res['error'] == false
            File.open("#{Rails.root}/tmp/nlims_token",'w') {|f|
              f.write(res['data']['token'].to_s)
            }
            puts res['message'] +"! can now access nlims resources"

        else

          puts res['message']  
        end 


  end


  desc "TODO"
  task create_order_to_nlims: :environment do
    settings = YAML.load_file("#{Rails.root}/config/application.yml")
    configs = YAML.load_file "#{Rails.root}/config/nlims_connection.yml"

    data = UnsyncOrder.find_by_sql("SELECT specimens.drawn_by_id AS drawn_id, specimens.drawn_by_name AS drawn_name,specimens.id AS specimen_id, specimens.tracking_number,specimens.priority,specimens.date_of_collection,specimen_types.name AS specimen_type ,specimen_statuses.name AS sample_status FROM unsync_orders                        
                                    INNER JOIN specimens ON specimens.id = unsync_orders.specimen_id 
                                    INNER JOIN specimen_types ON specimens.specimen_type_id = specimen_types.id
                                    INNER JOIN specimen_statuses ON specimen_statuses.id = specimens.specimen_status_id           
                                  WHERE (data_level='specimen' AND sync_status='not-synced') AND data_not_synced='new order'")
    data.each do |order|
      json = {}
      tracking_number = order.tracking_number 
      priority = order.priority
      date_of_collection = order.date_of_collection
      sample_status = order.sample_status
      sample_type = order.specimen_type
      sample_id = order.specimen_id
      drawn_first_name = order.drawn_name.split(" ")[0] rescue " "
      drawn_last_name = order.drawn_name.split(" ")[1] rescue " "
      drawn_id = order.drawn_id

        p_first_name = ""
        p_last_name = ""
        p_dob = ""
        p_gender = ""
        p_id = ""
        p_phone = ""
        ward = ""


      tests_ = []
      test_id = 0
      tests =  Test.find_by_sql("SELECT tests.id AS test_id, test_types.name AS test_name                        
                        FROM tests 
                        INNER JOIN test_types ON test_types.id = tests.test_type_id
                        WHERE tests.specimen_id ='#{sample_id}'"                      
                      )
      tests.each do |tst|
        tests_.push(tst.test_name)
        test_id = tst.test_id
      end

      vst = Visit.find_by_sql("SELECT ward_or_location AS ward, patients.name AS pat_name, patients.dob, patients.gender,
                        patients.phone_number, patients.patient_number
                        FROM visits INNER JOIN tests ON tests.visit_id =  visits.id 
                        INNER JOIN patients ON patients.id = visits.patient_id
                        WHERE tests.id = '#{test_id}'
                        ")
      vst.each do |visit|
        p_first_name = visit.pat_name.split(" ")[0]
        p_last_name = visit.pat_name.split(" ")[1]
        p_dob = visit.dob
        p_gender = visit.gender
        p_id = visit.patient_number
        p_phone = visit.phone_number
        ward = visit.ward
      end
      json = {
             :tracking_number => tracking_number, 
             :district => settings['district'],
             :health_facility_name => settings['facility_name'],           
             :sample_type=> sample_type,
             :date_sample_drawn=> date_of_collection,            
             :sample_status => sample_status.gsub("-","_"),
             :sample_priority=> priority || 'Routine',
             :target_lab=> settings['facility_name'],
             :art_start_date => "",
             :date_received => date_of_collection,
             :requesting_clinician => '',
             :return_json => 'true',
             :target_lab=> settings['facility_name'],
             :tests => tests_,
             :who_order_test_last_name=> drawn_last_name,
             :who_order_test_first_name=> drawn_first_name,
             :who_order_test_phone_number=> '',
             :who_order_test_id=> drawn_id,
             :order_location=> ward,             
             :first_name=> p_first_name,
             :last_name=> p_last_name,
             :middle_name=> "",
             :reason_for_test=> '',
             :date_of_birth=> p_dob.to_date.strftime("%a %b %d %Y"),
             :gender=> (p_gender == 1 ? "F" : "M"),
             :patient_residence => "",
             :patient_location => "",
             :patient_town => "",
             :patient_district => "",
             :national_patient_id=>  p_id,
             :phone_number=> '0000',
          }
          
          url = "#{configs['nlims_controller_ip']}/api/v1/create_order/"
          headers = {
            content_type: "application/json",
            token: "DRp62QHrm1QO" 
          }
          
          status = ApplicationController.up?("#{configs['nlims_service']}")
          
          if status == true
            res = JSON.parse(RestClient.post(url,json,headers))
            if res['status'] == 200
                r = UnsyncOrder.find_by(sync_status: "not-synced", data_not_synced: "new order", specimen_id: sample_id)
                r.sync_status = "synced"
                r.save
            end
          end
          puts res
         
    end
  end

end

