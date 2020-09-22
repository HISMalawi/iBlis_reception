require 'nlims_service.rb'
class Sender

	def self.send_data(patient, specimen)
    order = {
        "_id" => specimen.tracking_number,
        "sample_status" => SpecimenStatus.find(specimen.specimen_status_id).name.titleize
    }
    configs = YAML.load_file("#{Rails.root}/config/nlims_connection.yml")
   
        update_details = {
          "tracking_number": order['_id']
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
              'first_name': who.name.strip.scan(/^\w+/).first,
              'last_name': who.name.strip.scan(/\w+$/).last,
              'id_number': who.id
            }

            if specimen.specimen_status_id == 2
              test.test_status_id = 3
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
            res = NlimsService.update_test(update_details)
        end      

  end

  def self.create_order_remote(data)
    _token = File.read("#{Rails.root}/tmp/nlims_token")
    settings = YAML.load_file("#{Rails.root}/config/application.yml")["#{Rails.env}"]
    nlims = YAML.load_file("#{Rails.root}/config/nlims_connection.yml")
  
    headers = {
      content_type: "application/json",
      token: _token
    }    
    url  = "#{nlims['nlims_controller_ip']}/api/v1/create_order"
    res = JSON.parse(RestClient.post(url,data,headers))


    if res['error'] == false
			return [res['data']['tracking_number'],true]
		else
			return  [res['message'],false]
		end

    
  end
end

