require 'io/console'

settings = YAML.load_file("#{Rails.root}/config/application.yml")
configs = YAML.load_file "#{Rails.root}/config/nlims_connection.yml"
token_ = ""

if !File.exists?("#{Rails.root}/public/sample_tracker")
    FileUtils.touch("#{Rails.root}/public/sample_tracker")   
end






#-----------------------------------------------------------------------------

def self.generate_tracking_number
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
      value = counter.to_s
    end
    

    tracking_number = "X" + site_code + year.to_s +  get_month(month).to_s +  get_day(day).to_s + value.to_s
    
  end
  return tracking_number
end

#-----------------------------------------------------------------------------------

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

#----------------------------------------------------------------------------------

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

def measure_look_up(measure)
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
    "Sickle" => "Sickling Screen"
  }
  return measures[measure] if !measures[measure].blank?
  return measure if measures[measure].blank?
end

def test_type_look_up(test)
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
  return test_types[test] if !test_types[test].blank?
  return test if test_types[test].blank?
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

#----------------------------------------------------------------------------------
puts "-------------------------------------------------------------------------------------------------------------"
puts "checking for orderes having sam tracking number from iblis database before migration"
dupl = Specimen.find_by_sql("SELECT tracking_number, count(*) FROM specimens group by tracking_number having count(*) > 1")
dup_total = dupl.length

if dup_total > 0
  puts "-------------------------------------------------------------------------------------------------------------"
  puts "duplicats found: #{dup_total}"
  puts "-------------------------------------------------------------------------------------------------------------"
  puts "now resolving duplicates, please wait............."

  dupl.each do |dupl_rec|
    if !dupl_rec['tracking_number'].blank?
      da = Specimen.find_by_sql("SELECT * FROM specimens WHERE tracking_number='#{dupl_rec['tracking_number']}'")
      da.each do |reso|
        id_ = reso['id']
        updater = Specimen.find_by(id: id_)
        updater.tracking_number = generate_tracking_number
        updater.save       
        prepare_next_tracking_number     
      end
    end  
  end
  puts "-------------------------------------------------------------------------------------------------------------"
  puts "finished resolving duplicates, now can migrate the data"
else
  puts "-------------------------------------------------------------------------------------------------------------"
  puts "now duplicates found, now can migrate the data"
end

puts "new migration or continuation? (n/c)"
continue_from_last = gets.chomp

counter = 0
previous_tracking_number = ""
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
            
            tests_.push(test_type_look_up(tst.test_name))
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
          sample_type = sample_type.strip
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
              
              tracking_number = order.tracking_number  
              #if previous_tracking_number == order.tracking_number
              #   tracking_number = generate_tracking_number
              #    prepare_next_tracking_number
              #    r = Specimen.find_by(id: "#{sample_id}")
              #    r.tracking_number = tracking_number
              #    r.save
              #end

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
                
                  if order.tracking_number.blank?
                    r = Specimen.find_by(id: "#{sample_id}")
                    r.tracking_number = res['data']['tracking_number'] 
                    r.save
                    tracking_number = res['data']['tracking_number'] 
                  end
                  previous_tracking_number =  order.tracking_number
                  tests_with_statuses.each do |tst_status|                
                    status = tst_status[1]
                    test_n = test_type_look_up(tst_status[0])                       
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
                    test_n = test_type_look_up(rst_[2])
                    
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
                          next if measure_name.blank?
			  measure_name = measure_look_up(measure_name)
                          result_value = result_details.result_va
                          result_value = result_value.force_encoding("ASCII-8BIT").encode('UTF-8', undef: :replace, replace: '')
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
 
