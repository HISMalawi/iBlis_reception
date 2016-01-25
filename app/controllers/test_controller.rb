class TestController < ApplicationController
  def index

    accession_number_filter = ""

    unless params[:accession_number].blank?
      accession_number_filter = " AND tests.specimen_id IN (SELECT id FROM specimens WHERE accession_number = '#{params[:accession_number]}') "
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
        :location => test.visit.ward_or_location,
        :date_ordered =>  test.time_created,
        :test_name => test_name,
        :status => test.status.name,
        :specimen_name => test.specimen.specimen_type.name,
        :specimen_id => test.specimen.id,
        :patient_number => test.visit.patient.id,
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

    print_and_redirect("/test/print_accession_number?specimen_id=#{specimen.id}", "/tests/all?patient_id=#{visit.patient_id}")
  end

  def accept
    specimen = Specimen.find(params[:specimen_id])
    specimen.update_attributes(
        :specimen_status_id => SpecimenStatus.find_by_name("specimen-accepted").id,
        :accepted_by => User.current.id,
        :time_accepted => Time.now
      )

    redirect_to request.referrer
  end

  def reject
    @rejection_reasons = RejectionReason.all.map(&:reason)
  end

  def do_reject
    specimen = Specimen.find(params[:specimen_id])
    specimen.update_attributes(
        :specimen_status_id => SpecimenStatus.find_by_name("specimen-rejected").id,
        :rejected_by => User.current.id,
        :rejection_reason_id => RejectionReason.find_by_reason(params[:rejection_reason]).id,
        :reject_explained_to => params[:person_talked_to],
        :time_rejected => Time.now
    )

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
                  WHERE orderable_test = 1 AND id IN (SELECT test_type_id FROM testtype_specimentypes WHERE specimen_type_id = #{@specimen.specimen_type_id})"
    )

    tests = []
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
    @testtypes = (tests - already_ordered).uniq
  end

  def print_accession_number
    specimen = Specimen.find(params[:specimen_id])
    tests = specimen.tests
    accession_number = specimen.accession_number
    npid = tests.first.visit.patient.external_patient_number
    name = tests.first.visit.patient.name
    date = tests.first.time_created.strftime("%Y-%m-%d %H:%M:%S")

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

    tname = test_names.uniq.join('&')

    s='
N
q500
Q165,026
ZT
B50,105,0,1,4,8,50,N,"' + accession_number + '"
A35,30,0,2,1,1,N,"' + name + ' ' + npid + '"
A35,56,0,2,1,1,N,"' + tname + '"
A35,82,0,2,1,1,N,"' + date + '"
P1'

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

    redirect_to params[:return_uri]
  end

  def details
    @test = Test.find(params[:test_id])
    @specimen = @test.specimen
    @patient = @test.visit.patient

    render :layout => false
  end

  private
  def new_accession_number
    # Generate the next accession number for specimen registration

    max_acc_num = 0
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