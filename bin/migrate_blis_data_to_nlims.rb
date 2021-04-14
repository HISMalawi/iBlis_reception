require 'io/console'

settings = YAML.load_file("#{Rails.root}/config/application.yml")
configs = YAML.load_file "#{Rails.root}/config/nlims_connection.yml"
token_ = ""

if !File.exists?("#{Rails.root}/public/sample_tracker")
    FileUtils.touch("#{Rails.root}/public/sample_tracker")   
end

puts "new migration or continuation? (n/c)"
continue_from_last = gets.chomp

counter = 0
if continue_from_last == "c"
    last_sample_id = File.read("#{Rails.root}/public/sample_tracker")
    
    data = Specimen.find_by_sql("SELECT specimens.drawn_by_id AS drawn_id, specimens.drawn_by_name AS drawn_name,specimens.id AS specimen_id, 
                                specimens.tracking_number,specimens.priority,specimens.date_of_collection,specimen_types.name AS specimen_type_,
                                specimen_statuses.name AS sample_status FROM specimens                        
                                INNER JOIN specimen_types ON specimen_types.id = specimens.specimen_type_id
                                INNER JOIN specimen_statuses ON specimen_statuses.id = specimens.specimen_status_id 
                                WHERE specimens.id >=#{last_sample_id.to_i} ORDER BY specimens.id ASC")
    counter = last_sample_id.to_i
else 
    data = Specimen.find_by_sql("SELECT specimens.drawn_by_id AS drawn_id, specimens.drawn_by_name AS drawn_name,specimens.id AS specimen_id, 
                                specimens.tracking_number,specimens.priority,specimens.date_of_collection,specimen_types.name AS specimen_type_,
                                specimen_statuses.name AS sample_status FROM specimens                        
                                INNER JOIN specimen_types ON specimen_types.id = specimens.specimen_type_id
                                INNER JOIN specimen_statuses ON specimen_statuses.id = specimens.specimen_status_id
                                ORDER BY specimens.id ASC")
end

total = data.length
puts "----------------------------------------------------------------------------"
puts "migrating iblis data to nlims at central repository: Total Records: #{total}"
puts "----------------------------------------------------------------------------"
     
    
        headers = {
            content_type: "application/json"
        }          
                                      
        password = configs['nlims_default_password']
        username = configs['nlims_default_username']

        url = "#{configs['nlims_controller_ip']}/api/v1/re_authenticate/#{username}/#{password}"
        res = JSON.parse(RestClient.get(url,headers))
	
        if res['error'] == false
          token_ = res['data']['token']      
        end
    
    
    
        data.each do |order|      
          json = {}
                   
          priority = order.priority      
          sample_status = order.sample_status      
          sample_type = order.specimen_type_      
          sample_id = order.specimen_id
          drawn_first_name = order.drawn_name.split(" ")[0] rescue " "
          drawn_last_name = order.drawn_name.split(" ")[1] rescue " "
          drawn_id = order.drawn_id
          date_of_collection = ""
          
            p_first_name = ""
            p_last_name = ""
            p_dob = ""
            p_gender = ""
            p_id = ""
            p_phone = ""
            ward = ""
    
            
    
          tests_ = []
          test_id = 0
          tests_with_results = []
          tests_with_statuses = []
          tests =  Test.find_by_sql("SELECT tests.id AS test_id, test_types.name AS test_name, tests.time_created AS date_ordered,test_statuses.name AS test_status                        
                            FROM tests 
                            INNER JOIN test_types ON test_types.id = tests.test_type_id
                            INNER JOIN test_statuses ON test_statuses.id = tests.test_status_id
                            WHERE tests.specimen_id ='#{sample_id}'"                      
                          )
          
          tests.each do |tst|
            tests_.push(tst.test_name)
            test_id = tst.test_id
            
            user_name = ""
              if tst.test_status == "verified"
                
                updater = User.find_by_sql("SELECT users.name AS user_name FROM users INNER JOIN tests ON tests.verified_by = users.id
                                  WHERE tests.id ='#{test_id}'")
          
                user_name = updater[0]['user_name'] if !updater.blank?
                tests_with_results.push([test_id,tst.test_status,tst.test_name,user_name])  
                                
              elsif tst.test_status == "completed" 
                tests_with_results.push([test_id,tst.test_status,tst.test_name,""]) 
              else
                tests_with_statuses.push([tst.test_name,tst.test_status])
              end
            
            date_of_collection = tst.date_ordered
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
    
          birth_date =  p_dob.to_date.strftime("%a %b %d %Y") if !p_dob.blank?
          birth_date = date_of_collection if p_dob.blank?
    
          if order.tracking_number.blank?
            json = {
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
              :reason_for_test=> priority,
              :date_of_birth=> birth_date,
              :gender=> (p_gender == 1 ? "F" : "M"),
              :patient_residence => "",
              :patient_location => "",
              :patient_town => "",
              :patient_district => "",
              :national_patient_id=>  p_id,
              :phone_number=> '0000',
           }
    
          else
              tracking_number = order.tracking_number + "-M"  
    
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
                :reason_for_test=> priority,
                :date_of_birth=> birth_date,
                :gender=> (p_gender == 1 ? "F" : "M"),
                :patient_residence => "",
                :patient_location => "",
                :patient_town => "",
                :patient_district => "",
                :national_patient_id=>  p_id,
                :phone_number=> '0000',
             }
          end
    
              url = "#{configs['nlims_controller_ip']}/api/v1/create_order/"
              token_ = "sss"
              headers = {
		            content_type: "application/json",
                token: token_
              }
              json = JSON.generate(json)
              status = ApplicationController.up?("#{configs['nlims_service']}")
              
              if status == true
                res = JSON.parse(RestClient.post(url,json,headers))
                
                if res['status'] == 401 && res['message'] == "token expired"
                  url = "#{configs['nlims_controller_ip']}/api/v1/re_authenticate/#{username}/#{password}"
                  res = JSON.parse(RestClient.get(url,headers))
            
                  if res['error'] == false
                    token_ = res['data']['token']      
                  end

                  headers = {
                    content_type: "application/json",
                    token: token_
                  }
                  url = "#{configs['nlims_controller_ip']}/api/v1/create_order/"
                  res = JSON.parse(RestClient.post(url,json,headers))
                end
                if res['status'] == 200
                
                  #if order.tracking_number.blank?
                    r = Specimen.find_by(id: "#{sample_id}")
                    r.tracking_number = res['data']['tracking_number'] 
                    r.save
                    tracking_number = res['data']['tracking_number'] 
                  #end
                  
                  tests_with_statuses.each do |tst_status|                
                    status = tst_status[1]
                    test_n = tst_status[0]                       
                        json_ = {
                          :tracking_number => tracking_number,
                          :test_status => status,
                          :test_name => test_n,
                          :who_updated => {
                            :first_name => "",
                            :last_name => "",
                            :id => ""
                          }
                        }           
                        url = "#{configs['nlims_controller_ip']}/api/v1/update_test"    
                        json_ = JSON.generate(json_)                    
                        re = JSON.parse(RestClient.post(url,json_,headers))                                         
                        if re['status'] == 200
                          
                        end
                        
                  end

                  tests_with_results.each do |rst_|       
                    t_id = rst_[0]
                    status = rst_[1]
                    test_n = rst_[2]
                    updater = rst_[3]
                       
                        json_ = {
                          :tracking_number => tracking_number,
                          :test_status => status,
                          :test_name => test_n,
                          :who_updated => {
                            :first_name => updater.split(" ")[0],
                            :last_name => updater.split(" ")[1],
                            :id => ""
                          }
                        }
                        
                        res = TestResult.find_by_sql("SELECT test_results.result AS result_va,measures.name AS m_name,test_results.time_entered FROM test_results 
                                              INNER JOIN measures ON measures.id = test_results.measure_id
                                              WHERE test_results.test_id ='#{t_id}'")
                        r_date = ""
                        measures = {}
                        res.each do |result_details|              
                          measure_name = result_details.m_name
                          result_value = result_details.result_va 
                          measures[measure_name] = result_value
                          r_date = result_details.time_entered
                        end
                        
                        json_["results"] = measures
                        json_["result_date"] = r_date
                        json_ = JSON.generate(json_)
                        url = "#{configs['nlims_controller_ip']}/api/v1/update_test"
                        
                            re = JSON.parse(RestClient.post(url,json_,headers))                                    
                            if re['status'] == 200                              
                            end
                 
                  end
                  
                  File.open("#{Rails.root}/public/sample_tracker","w"){ |w|
                    w.write(sample_id)
                  }
                end
              end
               
              counter = counter + 1             
            puts "records migrated: #{counter}"
        end
 
