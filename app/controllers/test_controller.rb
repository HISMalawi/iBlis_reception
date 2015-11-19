class TestController < ApplicationController
  def index
    if params[:status] == 'all'
      tests = Test.all
    end
    
    @tests = {}
    (tests || []).each do |test|
      @tests[test.visit_id] = {} if @tests[test.visit_id].blank? 
      @tests[test.visit_id][test.specimen.specimen_type.name] = {} if @tests[test.visit_id][test.specimen.specimen_type.name].blank? 


      @tests[test.visit_id][test.specimen.specimen_type.name][test.test_type.name] = {:location => test.visit.ward_or_location,
        :date_ordered =>  test.time_created, :status => test.status.name,:specimen_name => test.specimen.specimen_type.name,
        :patient_number => test.visit.patient.patient_number,:visit_number => test.visit.id,
        :external_patient_number => test.visit.patient.external_patient_number,
        :specimen_id => test.specimen.accession_number,:test_id => test.id,:specimen_status => test.specimen.status.name,
        :patient_name => "#{test.visit.patient.name} (#{test.visit.patient.gender == 0 ? 'M' : 'F'},#{test.visit.patient.age})"}
    end

    render :layout => false
  end
end
