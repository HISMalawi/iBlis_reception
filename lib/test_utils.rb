require 'auto12epl'

module TestUtils
  def self.new_accession_number
    # Generate the next accession number for specimen registration
    @mutex = Mutex.new if @mutex.blank?
    @mutex.lock
    max_acc_num = 0
    return_value = nil
    sentinel = 99999999

    settings = YAML.load_file("#{Rails.root}/config/application.yml")
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

  def self.create_specimen_label(specimen_id, history="" )
    settings = YAML.load_file("#{Rails.root}/config/application.yml")
    specimen = Specimen.find(specimen_id)
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
        test_names << t.short_name || t.name
      else
        test_names << TestPanel.find(t.panel_id).panel_type.short_name || TestPanel.find(t.panel_id).panel_type.name
      end

    end

    tname = test_names.uniq.join(', ')
    first_name = name.strip.scan(/^\w+/).first.strip rescue ""
    last_name = name.strip.scan(/\w+$/).last.strip rescue ""
    middle_initial = name.strip.scan(/\s\w+\s/).first.strip[0 .. 2] rescue ""
    dob = patient.dob.to_date.strftime("%d-%b-%Y")
    age = patient.age
    gender = patient.gender == 0 ? "M" : "F"
    col_datetime = date
    col_by = User.find(tests.first.created_by).username
    formatted_acc_num = format_ac(specimen.accession_number)
    stat_el = specimen.priority.downcase.to_s == "stat" ? "STAT" : nil
    numerical_acc_num = numerical_ac(specimen.accession_number)

    auto = Auto12Epl.new
    s =  auto.generate_epl(last_name.to_s, first_name.to_s, middle_initial.to_s, npid.to_s, dob, age.to_s,
                           gender.to_s, col_datetime, col_by.to_s, tname.to_s,
                           stat_el, formatted_acc_num.to_s, numerical_acc_num)

    if !history.blank?
      s += "\n##########BEGIN FORM##########\n\n"
      s += "\nN\nq616\nQ026,0\nZT\n"
      s += "A150,50,0,3,1,1,N,\"#{settings['facility_name']}\"\n"
      s += "A80,90,0,3,1,1,N,\"Laboratory Test Order Form V2.0.0\"\n"
      s += "A30,130,0,3,1,1,N,\"Patient : #{patient.name} (#{gender})\"\n"
      s += "A30,170,0,3,1,1,N,\"Patient ID : #{npid}\"\n"
      s += "A30,210,0,3,1,1,N,\"Patient DOB: #{dob}\"\n"
      s += "A30,250,0,3,1,1,N,\"Ordered By : #{tests.first.requested_by}\"\n"
      s += "A30,290,0,3,1,1,N,\"Ordered From : #{tests.first.visit.ward_or_location}\"\n"
      s += "A30,330,0,3,1,1,N,\"Specimen Type : #{specimen.specimen_type.name}\"\n"
      s += "A30,370,0,3,1,1,N,\"Priority : #{specimen.priority}\"\n"
      s += "A30,410,0,3,1,1,N,\"Collected at : #{specimen.date_of_collection.strftime("%d %b, %Y %H:%M")}\"\n"
      s += "A30,450,0,3,1,1,N,\"Clinical History : #{history}\"\n"
      s += "A30,490,0,3,1,1,N,\"Tests\"\n"
      line = 530
      test_names.each do |name|
        s += "A50,#{line},0,3,1,1,N,\"-#{name}\"\n"
        line +=40
      end
      s += "B180,#{line},0,1A,2,2,120,N,\"#{numerical_acc_num}\"\n"
      s += "P1\n\n"
    end

    return s
  end

  def self.format_ac(num)
    num = num.insert(3, '-')
    num = num.insert(-9, '-')
    num
  end

  def self.numerical_ac(num)
    settings = YAML.load_file("#{Rails.root}/config/application.yml")
    code = settings['facility_code']
    num = num.sub(/^#{code}/, '')
    num
  end
end
