class PeopleController < ApplicationController
  def find
    settings = YAML.load_file("#{Rails.root}/config/application.yml")["#{Rails.env}"]

    npid = ""
    tracking_number = params[:identifier]

    @openmrs_people = []
    @local_people = []
    @remote_results = []
    @patients = []

    if params[:identifier] && (params[:identifier].length == 6 || params[:identifier].length == 12)
      npid = params[:identifier]

      @local_people = Patient.where(:external_patient_number => params[:identifier])
      @openmrs_people = Openmrs.search_by_npid(npid) #search from openmrs
    end

    remote_url = "#{settings['central_repo']}/query_order/#{tracking_number}"
    @remote_results = JSON.parse(RestClient.get(remote_url))

    if !params[:identifier].blank? && @patients.length == 1
      redirect_to '/people/view?patient_id=' + @patients.first.id.to_s and return
    end

    @patients = @local_people
    unless @patients.blank?
      render :layout => false, :template => '/people/people_search_results'
    end

  end

  def family_names
    search("family_name", params[:search_string])
  end
  
  def given_names
    search("given_name", params[:search_string])
  end
  
  def search(field_name, search_string)
    i = 0 if field_name == 'given_name'
    i = 1 if field_name == 'family_name'
    names = Patient.where("name LIKE (?)", "%#{search_string}").limit(20).map {|pat| pat.name.split(' ')[i] }
    render :text => "<li>" + names.uniq.map{|n| n } .join("</li><li>") + "</li>"
  end

  def addresses
    names = Patient.where("address LIKE (?)", "#{params[:search_string]}%").limit(20).map {|pat| pat.address }
    render :text => "<li>" + names.uniq.map{|n| n } .join("</li><li>") + "</li>"
  end

  def people_search_results
    given_name = params[:name]['given_name'] ; family_name = params[:name]['family_name']
    @patients = Patient.where("name LIKE (?) AND gender = ?", 
      "%#{given_name} #{family_name}",params[:gender]).limit(20)

    render :layout => false
  end

  def create

    patient = Patient.create(:name => "#{params[:person]['names']['given_name']} #{params[:person]['names']['family_name']}",
      :created_by => User.current.id,
      :address => params[:person]['addresses']['physical_address'],
      :phone_number => params[:cell_phone_number],
      :gender => params[:gender],
      :patient_number => (Patient.count + 1),
      :dob => calDOB(params),
      :external_patient_number => (params[:identifier] || '')
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
      wards += Ward.find_by_sql("SELECT name from facilities").map(&:name)
    end

    wards = wards.reject{|w| !w.match(/#{params[:search_string]}/i) || w.match(/^facilities$/i)}
    render :text => "<li>" + wards.uniq.map{|n| n } .join("</li><li>") + "</li>"
  end

  def view
    @patient = Patient.find(params[:patient_id])
    render :layout => false
  end

  def edit
    @patient = Patient.find(params[:patient_id])
  end

  def update
    Patient.find(params[:patient_id]).update_attributes(
          :name => "#{params[:given_name]} #{params[:family_name]}",
          :address => params[:physical_address],
          :phone_number => params[:cell_phone_number],
          :gender => params[:gender],
          :dob => calDOB(params)
    )

    redirect_to params[:return_uri]
  end

  def barcode
    print_and_redirect("/people/print_barcode?patient_id=#{params[:patient_id]}", "/people/view?patient_id=#{params[:patient_id]}")
  end

  private

  def calDOB(params)
    if params[:person]['birth_year'] == "Unknown"
      birthdate = Date.new(Date.today.year - params[:person]["age_estimate"].to_i, 7, 1)
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
