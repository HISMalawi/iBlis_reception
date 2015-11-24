class PeopleController < ApplicationController
  def find
    @patients = Patient.where(:external_patient_number => params[:identifier])

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
      :created_by => User.current.id,:address => params[:person]['addresses']['physical_address'],
      :phone_number => params[:cell_phone_number],:gender => params[:gender],:patient_number => (Patient.count + 1),
      :dob => calDOB(params),:external_patient_number => "KJ#{rand(100).to_s.rjust(6,'0')}")

    redirect_to "/test/new?patient_id=#{patient.id}"
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
