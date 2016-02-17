class TestController < ApplicationController
  def index

    accession_number_filter = ""

    unless params[:tracking_number].blank?
      accession_number_filter = " AND tests.specimen_id IN (SELECT id FROM specimens WHERE tracking_number = '#{params[:tracking_number]}') "
    end

    if params[:status] == 'all'
      if params[:patient_id].blank? #pull tests for all patients
        if params[:test_status_id] and params[:test_status_id].to_i != 0
          tests = Test.find_by_sql("SELECT * FROm tests WHERE test_status_id = #{params[:test_status_id]} #{accession_number_filter}
                                    ORDER BY time_created DESC LIMIT 100")
        else
          tests = Test.find_by_sql("SELECT * FROM tests WHERE true #{accession_number_filter} ORDER BY time_created DESC LIMIT 100")
        end
      else #pull tests for one patient
        if params[:test_status_id] and params[:test_status_id].to_i != 0
          tests = Test.find_by_sql("SELECT * FROM tests where test_status_id = #{params[:test_status_id]}
                              AND visit_id IN  (SELECT id FROM visits WHERE patient_id = #{params[:patient_id]}) #{accession_number_filter}
                              ORDER BY time_created DESC LIMIT 100")
        else
          tests = Test.find_by_sql("SELECT * FROM tests where visit_id IN  (SELECT id FROM visits WHERE patient_id = #{params[:patient_id]}) #{accession_number_filter}
                              ORDER BY time_created DESC LIMIT 100")
        end
      end
    end
    
    @tests = []
    panels = []
    (tests || []).each do |test|
      test_name = test.test_type.name
      next if panels.include?(test.panel_id)

      unless test.panel_id.blank?
        test_name = TestPanel.find(test.panel_id).panel_type.name
        panels << test.panel_id
      end

      @tests << {
        :tracking_number => test.specimen.tracking_number,
        :location => test.visit.ward_or_location,
        :date_ordered =>  test.time_created,
        :test_name => test_name,
        :status => test.status.name,
        :specimen_name => test.specimen.specimen_type.name,
        :specimen_id => test.specimen.id,
        :patient_id => test.visit.patient.id,
        :patient_number => test.visit.patient.patient_number,
        :visit_number => test.visit.id,
        :external_patient_number => test.visit.patient.external_patient_number,
        :accession_number => test.specimen.accession_number,
        :test_id => test.id,
        :specimen_status => test.specimen.status.name,
        :test_status => test.status.name,
        :patient_name => "#{test.visit.patient.name} (#{test.visit.patient.gender == 0 ? 'M' : 'F'},#{test.visit.patient.age})"}
    end

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
                  WHERE orderable_test = 1 AND id IN (SELECT test_type_id FROM testtype_specimentypes WHERE specimen_type_id = #{specimen_type_id})")
    paneled_tests = []
    testtypes.each do |type|
      tname = type.name
      tests << tname
      panel = Panel.where(:test_type_id => type.id).last rescue nil
      unless panel.blank?
        pname = panel.panel_type.name
        if !tests.include?(pname)
          tests << pname
        end
        paneled_tests << tname
      end
    end

    tests = tests - paneled_tests
    tests = tests.reject{|w| !w.match(/#{params[:search_string]}/i)}
    tests.sort!
    render :text => "<li>" + tests.uniq.map{|n| n } .join("</li><li>") + "</li>"
  end

  def create
    settings = YAML.load_file("#{Rails.root}/config/application.yml")[Rails.env]
    patient = Patient.find(params[:patient_id])

    #Patient Details
    first_name = patient.name.strip.scan(/^\w+\s/).first
    last_name = patient.name.strip.scan(/\s\w+$/).last
    middle_name = patient.name.strip.scan(/\s\w+\s/).last

    #Specimen Details

    json = { :return_path => "http://#{request.host}:#{request.port}",
             :district => settings['district'],
             :health_facility_name=> settings['facility_name'],
             :first_name=> first_name,
             :last_name=> last_name,
             :middle_name=> middle_name,
             :date_of_birth=> patient.dob.to_date.strftime("%a %b %d %Y"),
             :gender=> (patient.gender == 1 ? "F" : "M"),
             :national_patient_id=> patient.external_patient_number,
             :phone_number=> patient.phone_number,
             :reason_for_test=> '',
             :sample_collector_last_name=> '',
             :sample_collector_first_name=> '',
             :sample_collector_phone_number=> '',
             :sample_collector_id=> '',
             :sample_order_location=> params[:ward],
             :sample_type=> SpecimenType.find(params[:specimen_type]).name,
             :date_sample_drawn=> Date.today.strftime("%a %b %d %Y"),
             :tests=> params[:test_types].collect{|t| CGI.unescapeHTML(t)},
             :sample_priority=> 'Routine',
             :target_lab=> settings['facility_name'],
             :tracking_number => "",
             :art_start_date => "",
             :date_dispatched => "",
             :date_received => Date.today.strftime("%a %b %d %Y"),
             :return_json => 'true'
    }

    url = "#{settings['central_repo']}/create_hl7_order"
    response = JSON.parse(RestClient.post(url, json))
    paramz = response['params']

    tracking_number = paramz['tracking_number']
    acc_num = new_accession_number
    visit = Visit.new
    visit.patient_id = params[:patient_id]
    visit.visit_type = VisitType::find(params[:visit_type]).name
    visit.ward_or_location = params[:ward]
    visit.save

    if !params[:test_types].blank?
      specimen = Specimen.new
      specimen.specimen_type_id = params[:specimen_type]
      specimen.accepted_by = User.current.id
      specimen.priority = params[:priority].blank? ? 'Routine' : 'Stat'
      specimen.accession_number = acc_num
      specimen.tracking_number = tracking_number
      specimen.save
    end

    params[:test_types].each do |name|
      name = CGI.unescapeHTML(name)
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
          test.requested_by = CGI.unescapeHTML(params[:clinician])
          test.save
        end
      else
        test = Test.new
        test.visit_id = visit.id
        test.test_type_id = type.id
        test.specimen_id = specimen.id
        test.test_status_id = 2
        test.created_by = User.current.id
        test.requested_by = CGI.unescapeHTML(params[:clinician])
        test.save
      end
    end
    print_and_redirect("/test/print_accession_number?specimen_id=#{specimen.id}", "/tests/all?patient_id=#{visit.patient_id}")
  end

  def accept
    specimen = Specimen.find(params[:specimen_id])
    patient = specimen.tests.last.visit.patient

    specimen.update_attributes(
        :specimen_status_id => SpecimenStatus.find_by_name("specimen-accepted").id,
        :accepted_by => User.current.id,
        :time_accepted => Time.now
    )
    Sender.send_data(patient, specimen)
    redirect_to request.referrer
  end

  def save_remote
    data = JSON.parse(params[:data])
    identifier = params[:identifier]

    patient = Patient.where(
        :external_patient_number => data['patient']['national_patient_id']
    ).last

    if patient.blank?
      patient = Patient.new
    end

    patient.external_patient_number = data['patient']['national_patient_id']
    patient.name = (data['patient']['first_name'] + " " + data['patient']['middle_name'].to_s + " " + data['patient']['last_name']).squish
    patient.dob = data['patient']['date_of_birth']
    patient.gender = (data['patient']['gender'].match(/m/i) ? 0 : 1)
    patient.phone_number = data['patient']['phone_number']
    patient.patient_number = (Patient.count + 1) if patient.patient_number.blank?
    patient.external_patient_number = data['patient']['national_patient_id']
    patient.save!

    specimen = Specimen.where(:tracking_number => data['_id'] ).last
    if specimen.blank?
      specimen = Specimen.new
      specimen.specimen_type_id = SpecimenType.where(:name => data['sample_type']).last.id
      specimen.accession_number = new_accession_number
      specimen.tracking_number = data['_id']
      specimen.drawn_by_name = (data['who_order_test']['first_name'].to_s + ' ' +
          data['who_order_test']['middle_name'].to_s + ' ' +
          data['who_order_test']['last_name'].to_s).squish
      specimen.drawn_by_id = data['who_order_test']['id_number']
    end

    specimen.priority = data['priority']
    specimen.time_accepted = data['date_received']
    specimen.save!

    (data['test_types'] || []).each do |name|
      name = CGI.unescapeHTML(name)
      type = TestType.find_by_name(name).id rescue next

      test = specimen.tests.where(:test_type_id => type).last
      if test.blank?
        test = Test.new
        test.test_type_id = type
        test.specimen_id = specimen.id
        test.test_status_id = 2
        test.created_by = User.current.id
        test.requested_by = specimen.drawn_by_name
      end

      visit = test.visit
      visit = Visit.new if visit.blank?
      visit.patient_id = patient.id
      visit.visit_type = VisitType.last
      visit.ward_or_location = data['order_location']
      visit.save!

      test.visit_id = visit.id
      test.save
    end

    redirect_to "/tests/all?tracking_number=#{specimen.tracking_number}"
  end


  def reject
    @rejection_reasons = RejectionReason.all.map(&:reason)
  end

  def do_reject
    specimen = Specimen.find(params[:specimen_id])
    patient = specimen.tests.last.visit.patient

    specimen.update_attributes(
        :specimen_status_id => SpecimenStatus.find_by_name("specimen-rejected").id,
        :rejected_by => User.current.id,
        :rejection_reason_id => RejectionReason.find_by_reason(params[:rejection_reason]).id,
        :reject_explained_to => params[:person_talked_to],
        :time_rejected => Time.now
    )

    Sender.send_data(patient, specimen)
    redirect_to params[:return_uri]
  end

  def view

  end

  def add_test
    @specimen = Specimen.find(params[:specimen_id])
    already_ordered = @specimen.tests.map(&:name)

    panels = Test.find_by_sql("SELECT * FROM tests WHERE panel_id IS NOT NULL and specimen_id = #{@specimen.id}").map(&:panel_id).uniq rescue []
    panels.each do |p|
      already_ordered << Panel.find(p).panel_type.name
    end

    testtypes = TestType.find_by_sql("SELECT * FROM test_types
                  WHERE orderable_test = 1 AND id IN (SELECT test_type_id FROM testtype_specimentypes WHERE specimen_type_id = #{@specimen.specimen_type_id})")

    tests = []
    paneled_tests = []
    testtypes.each do |type|
      tname = type.name
      tests << tname
      panel = Panel.where(:test_type_id => type.id).last rescue nil
      unless panel.blank?
        pname = panel.panel_type.name
        if !tests.include?(pname)
          tests << pname
        end
        paneled_tests << tname
      end
    end
    @testtypes = (tests - already_ordered - paneled_tests).uniq
  end

  def age(dob)
    now = Time.now.utc.to_date
    now.year - dob.year - ((now.month > dob.month || (now.month == dob.month && now.day >= dob.day)) ? 0 : 1)
  end
  def format_ac(num)
    num = num.insert(3, '-')
    num = num.insert(-9, '-')
    num
  end
  def print_accession_number
    require 'auto12epl'
    specimen = Specimen.find(params[:specimen_id])
    tests = specimen.tests
    patient = tests.first.visit.patient
    npid = patient.external_patient_number
    npid = "-" if npid.blank?
    name = patient.name
    date = tests.first.time_created.strftime("%d-%b-%Y %H:%M")

    test_names = []
    panels = []
    tests.each do |t|
      next if !t.panel_id.blank?  and panels.include?(t.panel_id)
      if t.panel_id.blank?
        test_names << t.name
      else
        test_names << TestPanel.find(t.panel_id).panel_type.name
      end

    end

    tname = test_names.uniq.join(', ')
    first_name = name.strip.scan(/^\w+/).first.strip rescue ""
    last_name = name.strip.scan(/\w+$/).last.strip rescue ""
    middle_initial = name.strip.scan(/\s\w+\s/).first.strip[0 .. 2] rescue ""
    dob = patient.dob.to_date.strftime("%d-%b-%Y")
    age = age(dob.to_date).to_s
    gender = patient.gender == 0 ? "M" : "F"
    col_datetime = date
    col_by = User.find(tests.first.created_by).username
    formatted_acc_num = format_ac(specimen.accession_number)

    auto = Auto12Epl.new
    s =  auto.generate_epl(last_name, first_name, middle_initial, npid, dob, age,
                           gender, col_datetime, col_by, tname,
                           nil, formatted_acc_num, specimen.tracking_number)

    send_data(s,
              :type=>"application/label; charset=utf-8",
              :stream=> false,
              :filename=>"#{specimen.id}-#{rand(10000)}.lbs",
              :disposition => "inline"
    )
  end


  def specimen_barcode
    test = Test.find(params[:test_id])
    print_and_redirect("/test/print_accession_number?specimen_id=#{test.specimen.id}", "/test/details?test_id=#{test.id}")
  end

  def do_add_test
    specimen = Specimen.find(params[:specimen_id])
    visit = Visit.find(specimen.tests.last.visit_id)

      type = TestType.find_by_name(params[:test_type])
      panel_type = PanelType.find_by_name(params[:test_type])

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
          test.requested_by = specimen.tests.last.requested_by
          test.save
        end
      else
        test = Test.new
        test.visit_id = visit.id
        test.test_type_id = type.id
        test.specimen_id = specimen.id
        test.test_status_id = 2
        test.created_by = User.current.id
        test.requested_by = specimen.tests.last.requested_by
        test.save
      end

    Sender.send_data(visit.patient, specimen)

    redirect_to params[:return_uri]
  end

  def details
    @test = Test.find(params[:test_id])
    @specimen = @test.specimen
    @patient = @test.visit.patient
    @test_name = ""
    if (@test.panel_id.blank?)
      @test_name = @test.test_type.name
    else
      @test_name = TestPanel.find(@test.panel_id).panel_type.name
    end

    render :layout => false
  end

  def clinicians_suggest
    search_string = (params[:search_string] || "").upcase

    search_insert = search_string.blank? ? " " : " AND requested_by REGEXP '#{search_string.strip}' "
    clinicians = Test.find_by_sql("SELECT requested_by, count(*) AS cc
                                      FROM tests
                                        WHERE COALESCE(requested_by, '') != ''  #{search_insert}
                                        GROUP BY requested_by
                                        ORDER BY cc DESC LIMIT 100;").map(&:requested_by)

    render :text => "<li></li><li " + clinicians.map{|clinician| "value=\"#{clinician}\">#{clinician}" }.join("</li><li ") + "</li>"
  end

  private
  def new_accession_number
    # Generate the next accession number for specimen registration
    @mutex = Mutex.new if @mutex.blank?
    @mutex.lock
    max_acc_num = 0
    return_value = nil
    sentinel = 99999999

    settings = YAML.load_file("#{Rails.root}/config/application.yml")[Rails.env]
    code = settings['facility_code']
    year = Date.today.year.to_s[2..3]

    record = Specimen.find_by_sql("SELECT * FROM specimens WHERE accession_number IS NOT NULL ORDER BY id DESC LIMIT 1").last.accession_number rescue nil

    if !record.blank?
      max_acc_num = record[5..20].match(/\d+/)[0].to_i #first 5 chars are for facility code and 2 digit year
    end

    if (max_acc_num < sentinel)
        max_acc_num += 1
    else
        max_acc_num = 1
    end

    max_acc_num = max_acc_num.to_s.rjust(8, '0')
    return_value = "#{code}#{year}#{max_acc_num}"
    @mutex.unlock

    return return_value
  end
end
