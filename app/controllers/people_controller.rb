class PeopleController < ApplicationController

  def find
    settings = YAML.load_file("#{Rails.root}/config/application.yml")
    nlims = YAML.load_file("#{Rails.root}/config/nlims_connection.yml")
    status = ApplicationController.up?("#{nlims['nlims_service']}")

    @result = {}
    npid = ""
    tracking_number = params[:identifier] || ""
    npid = params[:identifier].gsub(/\-/, '') rescue nil

    openmrs_people = []
    local_people = []
    remote_results = []
    @patients = []

    if tracking_number && tracking_number.match(/X/i)
      remote_url = "#{nlims['nlims_controller_ip']}/api/v1/query_order_by_tracking_number/#{tracking_number}"
      _token = File.read("#{Rails.root}/tmp/nlims_token")
     
      headers = {
        content_type: "application/json",
        token: _token
      }
      
      if status  == true
        remote_results = JSON.parse(RestClient.get(remote_url,headers)) 
        @result = {'type' => 'remote_order', 'data' => remote_results} if remote_results

        if @result['data'].blank?
          @result = {'type' => 'local_order',
                    'data' => Specimen.where(:tracking_number => tracking_number).last
          }
        end
      end
    elsif tracking_number.match(/^\d+$/)
      acc_num = settings['facility_code'] + tracking_number
      @result = {'type' => 'local_order',
                 'data' => Specimen.where(:accession_number => acc_num).last
      }
    end

    if @result['data'].blank? and params[:identifier]
      local_people = Patient.where(:external_patient_number => params[:identifier]).to_a
      openmrs_people = Openmrs.search_by_npid(npid).to_a rescue []
      @result = {'type' => 'people',
                 'data' => (local_people + openmrs_people)}
    end

    @result = {} if @result['data'].blank?

    if @result['type'] == 'local_order' and !@result['data'].blank?
      redirect_to "/tests/all/?tracking_number=" + tracking_number
    elsif @result['type'] == 'remote_order' and !@result['data'].blank?

      @data = @result['data']
      @is_supported_test = Test.supported?(@data['data']['tests'].keys)
      @trac_number = tracking_number
      render :layout => false, :template => "/test/preview_remote_order",
             :tracking_number => tracking_number and return
    elsif @result['type'] == 'people' and @result['data'].length == 1 and !local_people.blank?
      redirect_to '/people/view?patient_id=' + @result['data'].first.id.to_s and return
    elsif @result['type'] == "people" and @result['data'].length > 0
      @patients = @result['data']
      render :layout => false, :template => '/people/people_search_results' and return
    end
  end

  def family_names
    search("last_name_code", params[:search_string])
  end
  
  def given_names
    search("first_name_code", params[:search_string])
  end
  
  def search(field_name, search_string)
    
    search_string = "" if search_string.nil?
    i = 0 if field_name == 'first_name_code'
    i = 1 if field_name == 'last_name_code'

    names = Patient.where("#{field_name} LIKE '#{search_string.soundex}%' ").limit(20).map {|pat| pat.name.split(/\s+/)[i] }
    render :text => "<li>" + names.uniq.map{|n| n } .join("</li><li>") + "</li>"
  end

  def addresses
    names = Patient.where("address LIKE (?)", "#{params[:search_string]}%").limit(20).map {|pat| pat.address }
    render :text => "<li>" + names.uniq.map{|n| n } .join("</li><li>") + "</li>"
  end

  def people_search_results
    g_name =  params[:name]['given_name']
    f_name =  params[:name]['family_name']
    given_name = params[:name]['given_name'].soundex  rescue nil
    family_name = params[:name]['family_name'].soundex rescue nil
    
    @patients = Patient.where("first_name_code = ? AND last_name_code = ? AND gender = ?",
     "#{given_name}" ,"#{family_name}", params[:gender]).limit(50)
    @exact_patients = []

    @patients.each do |p|
      @exact_patients << p if p.name.downcase == ((params[:name]['given_name'] + " " + params[:name]['family_name']).downcase rescue nil)
    end

    @patients = (@exact_patients + @patients).uniq
    render :layout => false
  end

  def create

    first_name = params[:person]['names']['given_name']
    last_name = params[:person]['names']['family_name']
    first_name = first_name.gsub("qt0","'")
    last_name =  last_name.gsub("qt0","'")

    patient = Patient.create(
      :name => "#{first_name} #{last_name}",
      :first_name_code => first_name.soundex,
      :last_name_code => last_name.soundex,
      :created_by => User.current.id,
      :address => params[:person]['addresses']['physical_address'],
      :phone_number => params[:cell_phone_number],
      :gender => params[:gender].match(/F/i) ? 1 : 0,
      :patient_number => (Patient.count + 1),
      :dob => calDOB(params),
      :dob_estimated => (params[:person]['birth_year'] == "Unknown") ? 1 : 0,
      :external_patient_number => (params[:person]['npid'] == 'Unknown') ? '' : params[:person]['npid'].gsub("$", "")
    )

    redirect_to "/test/new?patient_id=#{patient.id}&return_uri=#{request.referrer}"
  end

  def print_barcode
    patient = Patient.find(params[:patient_id])
    name = patient.name rescue "Unknown"
    npid = patient.external_patient_number rescue "Unknown"
    dob = patient.dob.strftime("%d-%m-%Y") rescue "Unknown"
    s = '
N
q801
Q329,026
ZT
B50,180,0,1,4,15,120,N,"' + npid + '"
A35,30,0,2,2,2,N,"' +  npid + '"
A35,76,0,2,2,2,N,"' + patient.name + '(' + dob + ')"
P1'

        send_data(s,
                  :type=>"application/label; charset=utf-8",
                  :stream=> false,
                  :filename=>"#{patient.external_patient_number}#{patient.id}#{rand(10000)}.lbl",
                  :disposition => "inline"
        )
  end

  def ward
    visit_id = (params[:filter_value])
    wards = Ward.find_by_sql("SELECT * FROM wards WHERE id IN (SELECT ward_id FROM visittype_wards WHERE visit_type_id = #{visit_id})").map(&:name).uniq
    if wards.include?("Facilities")
      wards += Ward.find_by_sql("SELECT name from facilities UNION SELECT 'Other' AS name ").map(&:name)
    end

    wards = wards.reject{|w| !w.match(/#{params[:search_string]}/i) || w.match(/^facilities$/i)}
    render :text => "<li>" + wards.uniq.map{|n| n } .join("</li><li>") + "</li>"
  end

  def view
    if params[:patient_id].blank? || params[:patient_id].to_i == 0
      @patient = Patient.where(:external_patient_number => params[:external_patient_number],
                               :name => EncryptionWrapper.cryptize(params[:name]),
                               :gender => ({'Male' => 0, 'Female' => 1}[params[:gender]]) || params[:gender]
      ).last

      split_name = params[:name].split(/\s+/)[0] rescue []
      first_name_code = split_name.first.soundex rescue nil
      last_name_code = (split_name.length > 1 ? split_name.last.soundex : nil) rescue nil

      @patient = Patient.new if @patient.blank?
      @patient.patient_number = Patient.count + 1 if @patient.patient_number.blank?
      @patient.external_patient_number = params[:external_patient_number]
      @patient.name = params[:name]
      @patient.first_name_code = first_name_code
      @patient.last_name_code = last_name_code
      @patient.dob = params[:dob].to_date
      @patient.gender = ({'Male' => 0, 'Female' => 1}[params[:gender]]) || params[:gender]
      @patient.address = params[:address]
      @patient.save
      @patient = Patient.find(@patient.id)
    else
      @patient = Patient.find(params[:patient_id])
    end
    render :layout => false
  end

  def edit
    @patient = Patient.find(params[:patient_id])
  end

  def update

    first_name = params[:given_name] || ""
    last_name = params[:family_name] || ""

    Patient.find(params[:patient_id]).update_attributes(
          :name => "#{first_name} #{last_name}",
          :first_name_code => first_name.soundex,
          :last_name_code => last_name.soundex,
          :address => params[:physical_address],
          :external_patient_number => (params[:npid] == 'Unknown') ? '' : params[:npid],
          :phone_number => params[:cell_phone_number],
          :gender => params[:gender],
          :dob => calDOB(params),
          :dob_estimated => (params[:person]['birth_year'] == "Unknown") ? 1 : 0
    )

    redirect_to params[:return_uri]
  end

  def barcode
    print_and_redirect("/people/print_barcode?patient_id=#{params[:patient_id]}", "/people/view?patient_id=#{params[:patient_id]}")
  end

  private

  def calDOB(params)
    if params[:person]['birth_year'] == "Unknown"
      birthdate = Date.new(Date.today.year - params[:person]["age_estimate"].to_i, 7, 15)
    else
      year = params[:person]["birth_year"].to_i
      month = params[:person]["birth_month"]
      day = params[:person]["birth_day"].to_i

      month_i = (month || 0).to_i
      month_i = Date::MONTHNAMES.index(month) if month_i == 0 || month_i.blank?
      month_i = Date::ABBR_MONTHNAMES.index(month) if month_i == 0 || month_i.blank?

      if month_i == 0 || month == "Unknown"
        birthdate = Date.new(year.to_i,7,1)
      elsif day.blank? || day == "Unknown" || day == 0
        birthdate = Date.new(year.to_i,month_i,15)
      else
        birthdate = Date.new(year.to_i,month_i,day.to_i)
      end
    end

    return birthdate
  end

end
