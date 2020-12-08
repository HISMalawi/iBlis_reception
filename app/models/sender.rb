require 'nlims_service.rb'
class Sender

	def self.send_data(patient, specimen)
    order = {
        "_id" => specimen.tracking_number,
        "sample_status" => SpecimenStatus.find(specimen.specimen_status_id).name.titleize
    }
    configs = YAML.load_file("#{Rails.root}/config/nlims_connection.yml")
    status = ApplicationController.up?("#{configs['nlims_service']}")
        update_details = {
          "tracking_number" => order['_id']
        }
        tests = specimen.tests
        tests.each  do |test|
            who = User.current
            updater = {}
            results = {}
            test_name = test.test_type.name
            update_details['test_name'] = test_name
            update_details['test_status'] = TestStatus.find(test.test_status_id).name
            update_details['time_update'] = Date.today.strftime("%a %b %d %Y")

            updater = {
              'first_name'=> who.name.strip.scan(/^\w+/).first,
              'last_name'=> who.name.strip.scan(/\w+$/).last,
              'id_number'=> who.id
            }

            if specimen.specimen_status_id == 2
              test.test_status_id = 2
              test.save
            elsif specimen.specimen_status_id == 3
              test.test_status_id = 8
              test.save
            end

            update_details['who_updated'] = updater        
            order['results'] = {} if order['results'].blank?            
            r = {}

            test.test_results.each do |result|
              measure = Measure.find(result.measure_id) rescue next
              r["#{measure.name}"] = "#{result.result} #{measure.unit}"
            end

            update_details['results'] = r
            
          if status == true
            res = NlimsService.update_test(update_details)
          else
            if specimen.specimen_status_id == 2
              order = UnsyncOrder.new
              order.specimen_id = test.id
              order.data_not_synced = 'pending'    
              order.data_level = 'test'
              order.sync_status = 'not-synced'
              order.updated_by_name = User.current.name
              order.updated_by_id = User.current.id
              order.save
            elsif specimen.specimen_status_id == 3
              order = UnsyncOrder.new
              order.specimen_id = test.id
              order.data_not_synced = 'rejected'    
              order.data_level = 'test'
              order.sync_status = 'not-synced'
              order.updated_by_name = User.current.name
              order.updated_by_id = User.current.id
              order.save
            end

          end
        end      

  end

  def self.create_order_remote(data)
    
    _token = File.read("#{Rails.root}/tmp/nlims_token")
    settings = YAML.load_file("#{Rails.root}/config/application.yml")
    nlims = YAML.load_file("#{Rails.root}/config/nlims_connection.yml")
  
    status = ApplicationController.up?("#{nlims['nlims_service']}")
    
    headers = {
      content_type: "application/json",
      token: _token
    }  

      url  = "#{nlims['nlims_controller_ip']}/api/v1/create_order"
     
    
      if status == true
        res = JSON.parse(RestClient.post(url,data,headers)) 
      else
        res = NlimsService.create_local_tracking_number
        NlimsService.prepare_next_tracking_number        
      end


    if status == true
      if res['error'] == false
        return [res['data']['tracking_number'],true]        
      else
        return  [res['message'],false] 
      end
    else
      return [res,true]
    end

    
  end
end

