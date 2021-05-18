
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
    token_ = ""

    data = UnsyncOrder.find_by_sql("SELECT specimens.drawn_by_id AS drawn_id, specimens.drawn_by_name AS drawn_name,specimens.id AS specimen_id, specimens.tracking_number,specimens.priority,specimens.date_of_collection,specimen_types.name AS specimen_type ,specimen_statuses.name AS sample_status FROM unsync_orders                        
                                    INNER JOIN specimens ON specimens.id = unsync_orders.specimen_id 
                                    INNER JOIN specimen_types ON specimens.specimen_type_id = specimen_types.id
                                    INNER JOIN specimen_statuses ON specimen_statuses.id = specimens.specimen_status_id           
                                  WHERE (data_level='specimen' AND sync_status='not-synced') AND data_not_synced='new order'")

    headers = {
        content_type: "application/json",
        token: token_
    }          
                                  
    password = configs['nlims_default_password']
    username = configs['nlims_default_username']
    url = "#{configs['nlims_controller_ip']}/api/v1/re_authenticate/#{username}/#{password}"
    res = JSON.parse(RestClient.get(url,headers))

    if res['error'] == false
      token_ = res['data']['token']      
    end

    test_types = {
      "Hepatitis C" => "Hepatitis C Test",
      "Hepatitis B" => "Hepatitis B Test",
      "FBC (Paeds)" => "FBC",
      "Electrolytes (Paeds)" => "Electrolytes",
      "Renal Function Tests (Paeds)" => "Renal Function Test",
      "Glucose (Paeds)" => "Glucose",
      "Liver Function Tests (Paeds)" => "Liver Function Tests",
      "Hepatitis B test (Paeds)" => "Hepatitis B Test",
      "Hepatitis C test (Paeds)" => "Hepatitis C Test",
      "Urine chemistry (paeds)" => "Urine chemistries",
      "Urine Macroscopy (Paeds)" => "Urine Macroscopy",
      "Urine Microscopy (Paeds)" => "Urine Microscopy",
      "Malaria Screening (Paeds)" => "Malaria Screening",
      "Syphilis (Paeds)" => "Syphilis Test",
      "Minerals (Paeds)" => "Minerals",
      "Cell Count (Paeds)" => "Cell Count",
      "Culture & Sensitivity (Paeds)" => "Culture & Sensitivity",
      "Differential (Paeds)" => "Differential",
      "Gram Stain (Paeds)"  => "Gram Stain",
      "India Ink (Paeds)"  => "India Ink",
      "Stool Analysis (Paeds)" => "Stool Analysis",
      "Lipogram (Paeds)" => "Lipogram",
      "HbA1c (Paeds)" => "HbA1c",
      "Total Protein" => "Protein",
      "ZN" => "ZN Stain",
      "Urine chemistry" => "Urine chemistries",
      "sickle cell" => "Sickling Test",
      "Macroscopy" => "Urine Macroscopy",
      "Culture/sensistivity" => "Culture & Sensitivity",
      "TB Microscopy" => "TB Microscopic Exam",
      "cryptococcal antigen" => "Cryptococcus Antigen Test"
    }


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
      tests =  Test.find_by_sql("SELECT tests.id AS test_id, test_types.name AS test_name,tests.time_created AS time_created                        
                        FROM tests 
                        INNER JOIN test_types ON test_types.id = tests.test_type_id
                        WHERE tests.specimen_id ='#{sample_id}'"                      
                      )
      tests.each do |tst|
        name_ = tst.test_name
        name_ = test_types[tst.test_name] if !test_types[tst.test_name].blank?
        tests_.push(name_)
        test_id = tst.test_id
        date_of_collection = tst.time_created
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
      brth = p_dob.to_date.strftime("%a %b %d %Y") rescue nil
      json = {
             :tracking_number => tracking_number, 
             :district => settings['district'],
             :health_facility_name => settings['facility_name'],           
             :sample_type=> sample_type,
             :date_sample_drawn=> date_of_collection,            
             :sample_status => sample_status.gsub("-","_"),
             :sample_priority=> priority || 'Routine',            
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
             :date_of_birth=> brth,
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
            token: token_
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








  desc "TODO"
  task update_order_to_nlims: :environment do

    settings = YAML.load_file("#{Rails.root}/config/application.yml")
    configs = YAML.load_file "#{Rails.root}/config/nlims_connection.yml"
    token_ = ""

    headers = {
      content_type: "application/json",
      token: token_
    }          
                                  
    username = configs['nlims_custome_password']
    password = configs['nlims_custome_username']
    url = "#{configs['nlims_controller_ip']}/api/v1/re_authenticate/#{username}/#{password}"
    res = JSON.parse(RestClient.get(url,headers))
    if res['error'] == false
      token_ = res['data']['token']      
    end
    
    res = UnsyncOrder.find_by_sql("SELECT specimens.id AS sample_id, specimens.tracking_number, unsync_orders.data_not_synced AS sample_status, 
                                    unsync_orders.updated_by_name AS updater, unsync_orders.updated_by_id AS updater_id FROM unsync_orders                        
                                    INNER JOIN specimens ON specimens.id = unsync_orders.specimen_id          
                                  WHERE (data_level='specimen' AND sync_status='not-synced') AND 
                                  (data_not_synced='specimen-rejected' OR data_not_synced='specimen-accepted' OR data_not_synced='specimen-collected' OR data_not_synced='accept specimen')")
    if !res.blank?
      res.each do |order|
      
        json = {}
        tracking_number = order.tracking_number
        sample_status = order.sample_status.gsub("-","_")
        updater_f_name =  order.updater.split(" ")[0]
        updater_l_name =  order.updater.split(" ")[1]
        updater_f_name = "N/A" if  order.updater.split(" ")[0].blank?
        updater_l_name = "N/A" if order.updater.split(" ")[1].blank?
        updater_id = order.updater_id
        sample_id = order.sample_id

        json = {
          :tracking_number => tracking_number,
          :status => sample_status,
          :who_updated => {
            :first_name => updater_f_name,
            :last_name => updater_l_name,
            :id => updater_id
          }
        }

        headers = {
          content_type: "application/json",
          token: token_
        }        
       

        url = "#{configs['nlims_controller_ip']}/api/v1/update_order"
        status = ApplicationController.up?("#{configs['nlims_service']}")
      
          if status == true
            re = JSON.parse(RestClient.post(url,json,headers))
            
            if re['status'] == 200
                r = UnsyncOrder.find_by(sync_status: "not-synced", data_not_synced: "#{order.sample_status}", specimen_id: sample_id)
                r.sync_status = "synced"
                r.save
            end
          end
        puts re          
      end
    end

  end

  desc "TODO"
  task update_test_to_nlims: :environment do

    settings = YAML.load_file("#{Rails.root}/config/application.yml")
    configs = YAML.load_file "#{Rails.root}/config/nlims_connection.yml"
    token_ = ""

    headers = {
      content_type: "application/json",
      token: token_
    }          

     measures = {
      "ALPU" => "ALP-H",
      "Urea/Bun" => "Urea",
      "Glu" => "Glucose",
      "Bilirubin Total(BIT))" => "Bilirubin Total(BIT)",
      "Epithelial cell" => "Epithelial cells",
      "Cast" => "Casts",
      "Yeast cell" => "Yeast cells",
      "HepB" => "Hepatitis B",
      "ALT" => "ALT-H",
      "AST" => "AST-H",
      "ALP" => "ALP-H",
      "ALB" => "ALB-H",
      "TBIL-VOX" => "Bilirubin Total(TBIL-VOX)",
      "DBIL-VOX" => "Bilirubin Direct(DBIL-VOX)",
      "HDL-C"  => "HDL Direct (HDL-C)",
      "LDL-C" => "LDL Direct (LDL-C)",
      "Cholestero l(CHOL)" => "Cholesterol(CHOL)",
      "r-GT" => "GGT/r-GT",
      "DBIL-DSA" => "DBIL-DSA-H",
      "TBIL-DSA" => "TBIL-DSA-H",
      "TP" => "TP-H",
      "Results" => "Blood film",
      "GGT" => "GGT/r-GT",
      "Sickling Screen By Sodium Metabiosulphate Method" => "Sickling Screen",
      "P_LCR" => "P-LCR",
      "Total Cholesterol(CHOL)" => "Cholesterol(CHOL)",
      "GLU-O" => "GLU-O-H",
      "TG" => "TG-H",
      "Sickle" => "Sickling Screen",
      "Cholestero l(CHOL)" => "Cholesterol(CHOL)"

    }
                           
    password = configs['nlims_default_password']
    username = configs['nlims_default_username']
    url = "#{configs['nlims_controller_ip']}/api/v1/re_authenticate/#{username}/#{password}"
    res = JSON.parse(RestClient.get(url,headers))

    if res['error'] == false
      token_ = res['data']['token']      
    end
    
    res = UnsyncOrder.find_by_sql("SELECT specimens.id AS sample_id,unsync_orders.specimen_id AS test_id ,specimens.tracking_number, 
                                    unsync_orders.data_not_synced AS test_status, unsync_orders.updated_by_name AS updater, 
                                    unsync_orders.updated_by_id AS updater_id, unsync_orders.updated_at 
                                    FROM unsync_orders    
                                    INNER JOIN tests ON tests.id = unsync_orders.specimen_id                     
                                    INNER JOIN specimens ON specimens.id = tests.specimen_id          
                                  WHERE unsync_orders.data_level='test' AND unsync_orders.sync_status='not-synced'")
          
 
    if !res.blank?
      res.each do |order|
        tst_name = Test.find_by_sql("SELECT test_types.name AS test_name FROM tests INNER JOIN test_types ON test_types.id = tests.test_type_id WHERE tests.id='#{order.test_id}'")
        tst_name = tst_name[0].test_name if !tst_name.blank?
    
        puts tst_name
      
        tracking_number = order.tracking_number
        test_status = order.test_status.gsub("-","_")
        updater_f_name =  order.updater.split(" ")[0]
        updater_l_name =  order.updater.split(" ")[1]
        updater_f_name = "N/A" if  order.updater.split(" ")[0].blank?
        updater_l_name = "N/A" if order.updater.split(" ")[1].blank?
        updater_id = order.updater_id
        sample_id = order.sample_id
        result_date = order.updated_at
        test_status = "completed" if test_status == "result"
        result_date = "" if test_status != "result"
        json = {
            :tracking_number => tracking_number,
            :test_status => test_status,
            :test_name => tst_name,
            :result_date => result_date,
            :who_updated => {
              :first_name => updater_f_name,
              :last_name => updater_l_name,
              :id => updater_id
            }
          }

        if order.test_status == "result"          
          t_r = TestResult.find_by_sql("SELECT measures.name AS m_name, test_results.result AS result_va FROM test_results 
                                INNER JOIN tests ON tests.id = test_results.test_id 
                                INNER JOIN measures ON measures.id = test_results.measure_id
                                WHERE test_results.test_id='#{order.test_id}'")
          measures = {}
          if !t_r.blank?
            t_r.each do |rs_data|
              measure_name = rs_data.m_name
              measure_name = measures[measure_name] if !measures[measure_name].blank?
              result_value = rs_data.result_va 
              measures[measure_name] = result_value
            end
          end
          json["results"] = measures            
        end

       puts json
        headers = {
          content_type: "application/json",
          token: token_
        }        
       

        url = "#{configs['nlims_controller_ip']}/api/v1/update_test"
        status = ApplicationController.up?("#{configs['nlims_service']}")
      
          if status == true
            re = JSON.parse(RestClient.post(url,json,headers))
            
            if re['status'] == 200
                r = UnsyncOrder.find_by(sync_status: "not-synced", data_not_synced: "#{test_status}", specimen_id: "#{order.test_id}")
                r.sync_status = "synced"
                r.save
            end
          end
          puts re   
      end 
         
    end

  end
  

end

