class TestController < ApplicationController
  def index
    if params[:status] == 'all'
      tests = Test.all
    end
    
    @tests = {}
    (tests || []).each do |test|
      @tests[test.specimen_id] = {} if @tests[test.specimen_id].blank?
      test_name = test.test_type.name

      unless test.panel_id.blank?
        test_name = TestPanel.find(test.panel_id).panel_type.name
      end

      @tests[test.specimen_id][test_name] = {} if @tests[test.specimen_id][test_name].blank?

      @tests[test.specimen_id][test_name] = {
        :location => test.visit.ward_or_location,
        :date_ordered =>  test.time_created,
        :status => test.status.name,:specimen_name => test.specimen.specimen_type.name,
        :patient_number => test.visit.patient.external_patient_number || test.visit.patient.patient_number,
        :visit_number => test.visit.id,
        :external_patient_number => test.visit.patient.external_patient_number,
        :accession_number => test.specimen.accession_number,
        :test_id => test.id,
        :specimen_status => test.specimen.status.name,
        :patient_name => "#{test.visit.patient.name} (#{test.visit.patient.gender == 0 ? 'M' : 'F'},#{test.visit.patient.age})"}
    end

    render :layout => false
  end

  def new
    @patient = Patient.find(params[:patient_id])
    @specimen_types = [[]] + SpecimenType.all().collect{|type| [type['name'], type.id]}
    @visit_types = [[]] + VisitType.all().collect{|visit| [visit['name'], visit.id]}
  end

  def types
    specimen_type_id = (params[:filter_value])
    tests = []
    testtypes = TestType.find_by_sql("SELECT * FROM test_types
                  WHERE id IN (SELECT test_type_id FROM testtype_specimentypes WHERE specimen_type_id = #{specimen_type_id})")
    testtypes.each do |type|
      tname = type.name
      tests << tname
      panel = Panel.where(:test_type_id => type.id).last rescue nil
      unless panel.blank?
        pname = panel.panel_type.name
        if !tests.include?(pname)
          tests << pname
        end
      end
    end

    tests = tests.reject{|w| !w.match(/#{params[:search_string]}/i)}
    tests.sort!
    render :text => "<li>" + tests.uniq.map{|n| n } .join("</li><li>") + "</li>"
  end

  def create
    visit = Visit.new
    visit.patient_id = params[:patient_id]
    visit.visit_type = VisitType::find(params[:visit_type]).name
    visit.ward_or_location = params[:ward]
    visit.save

    if !params[:test_types].blank?
      specimen = Specimen.new
      specimen.specimen_type_id = params[:specimen_type]
      specimen.accepted_by = User.current.id
      specimen.accession_number = new_accession_number
      specimen.save
    end

    params[:test_types].each do |name|
      type = TestType.find_by_name(name)
      panel_type = PanelType.find_by_name(name)

      if !panel_type.blank?
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
          test.created_by = User.current.id
          test.panel_id = test_panel.id
          test.requested_by = params[:clinician]
          test.save
        end
      else
        test = Test.new
        test.visit_id = visit.id
        test.test_type_id = type.id
        test.specimen_id = specimen.id
        test.test_status_id = 2
        test.created_by = User.current.id
        test.requested_by = params[:clinician]
        test.save
      end
    end

    redirect_to "/tests/all"
  end

  def new_accession_number
    # Generate the next accession number for specimen registration

    max_acc_num = 1
    return_value = nil
    sentinel = 999999

    code = "KCH"

    record = Specimen.find_by_sql("SELECT * FROM specimens  WHERE accession_number IS NOT NULL ORDER BY id DESC LIMIT 1").last.accession_number rescue nil

    if !record.blank?
      max_acc_num = record.match(/\d+/)[0].to_i
    end

    if (max_acc_num < sentinel)
        max_acc_num += 1
    else
        max_acc_num = 1
    end

    max_acc_num = max_acc_num.to_s.rjust(6, '0')
    return_value = "#{code}#{max_acc_num}"
    return return_value
  end
end