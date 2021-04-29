require 'nlims_service.rb'
require 'test_utils.rb'

class Test < BlisConnection
  self.table_name = "tests"
  
  belongs_to :test_type, class_name: 'TestType', foreign_key: "test_type_id"
  belongs_to :visit, class_name: 'Visit', foreign_key: "visit_id"
  belongs_to :specimen, class_name: 'Specimen', foreign_key: "specimen_id"
  belongs_to :status, class_name: 'TestStatus', foreign_key: "test_status_id"
  has_many :test_results, class_name: 'TestResult', foreign_key: "test_id"

  def name
    self.test_type.name rescue nil
  end
  def short_name
    self.test_type.short_name rescue nil
  end
  def self.supported?(test_types = [])
    test_types.each do |tname|
      return false if (TestType.find_by_name(tname).blank? && PanelType.find_by_name(tname).blank?)
    end
    return true
  end

  def self.create_order_from_scan(patient, segments)
    settings = YAML.load_file("#{Rails.root}/config/application.yml") # [Rails.env]

    #Patient Details
    first_name = patient.name.strip.scan(/^\w+\s/).first
    last_name = patient.name.strip.scan(/\s\w+$/).last
    middle_name = patient.name.strip.scan(/\s\w+\s/).last
    #date_sample_collected = segments[8].to_s
    date_sample_collected = Time.at(segments[8].to_i) #date_sample_collected.to_time.strftime("%Y%m%d%H%M%S")


    #Orderer
    clinician = CGI.unescapeHTML(segments[5].strip).split(/\s+/)
    c_last_name = clinician.last
    c_first_name = (clinician - [c_last_name]).join(" ") rescue ""
    clinician = CGI.unescapeHTML(segments[5].strip)

    json = {
      :district => settings['district'],
      :health_facility_name => settings['facility_name'],
      :first_name=> first_name,
      :last_name=> last_name,
      :middle_name=> middle_name,
      :date_of_birth=> patient.dob.to_date.strftime("%a %b %d %Y"),
      :gender=> (patient.gender == 1 ? "F" : "M"),
      :patient_residence => "",
      :patient_location => "",
      :patient_town => "",
      :patient_district => "",
      :national_patient_id=> patient.external_patient_number,
      :phone_number=> patient.phone_number,
      :reason_for_test=> '',
      :sample_collector_last_name=> c_last_name,
      :sample_collector_first_name=> c_first_name,
      :sample_collector_phone_number=> '',
      :sample_collector_id=> '',
      :sample_order_location=> (Ward.find(segments[4]).name rescue nil),
      :sample_type=> SpecimenType.find(segments[7]).name,
      :date_sample_drawn=> date_sample_collected,
      :tests=> segments[9].split("^").collect{|t_id| TestType.find(t_id).name},
      :sample_status => 'specimen_not_collected',
      :sample_priority=>  ({"S" => "STAT", "R" => "ROUTINE"}[segments[10]]),
      :target_lab=> settings['facility_name'],
      :art_start_date => "",
      :date_received => Time.now,
      :requesting_clinician => '',
      :return_json => 'true'
    }

    res = NlimsService.create_local_tracking_number
    NlimsService.prepare_next_tracking_number
    tracking_number = res

    acc_num = TestUtils.new_accession_number
    visit = Visit.new
    visit.patient_id = patient.id
    visit.visit_type = "In Patient"
    visit.ward_or_location = (Ward.find(segments[4]).name rescue nil)
    visit.save

    specimen = Specimen.new
    specimen.specimen_type_id = segments[7]
    specimen.accepted_by = User.current.id
    specimen.priority = ({"S" => "STAT", "R" => "ROUTINE"}[segments[10]])
    specimen.accession_number = acc_num
    specimen.tracking_number = tracking_number
    specimen.date_of_collection = date_sample_collected
    specimen.save

    order = UnsyncOrder.new
    order.specimen_id = specimen.id
    order.data_not_synced = 'new order'
    order.data_level = 'specimen'
    order.sync_status = 'not-synced'
    order.updated_by_name = User.current.name
    order.updated_by_id = User.current.id
    order.save

    if !segments[11].blank?
      panel_type = PanelType.find(segments[9])
      member_tests = Panel.where(:panel_type_id => panel_type.id)

      test_panel = TestPanel.new
      test_panel.panel_type_id = panel_type.id
      test_panel.save

      (member_tests || []).each do |m_test|
        test = Test.new
        test.visit_id = visit.id
        test.test_type_id = m_test.test_type_id
        test.specimen_id = specimen.id
        test.test_status_id = 2
        test.not_done_reasons = 0
        test.person_talked_to_for_not_done = 0
        test.created_by = User.current.id
        test.panel_id = test_panel.id
        test.requested_by = clinician
        test.save
      end
    else
      segments[9].split("^").each do |test_type_id|
        test = Test.new
        test.visit_id = visit.id
        test.test_type_id = test_type_id
        test.specimen_id = specimen.id
        test.test_status_id = 2
        test.created_by = User.current.id
        test.requested_by = clinician
        test.not_done_reasons = ''
        test.person_talked_to_for_not_done = ''
        test.save

      end

      #Sender.send_data(patient, specimen)
    end

    return specimen.id
  end
end
