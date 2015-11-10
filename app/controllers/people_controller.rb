class PeopleController < ApplicationController
  def find
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

  def people_search_results
    given_name = params[:name]['given_name'] ; family_name = params[:name]['family_name']
    @patients = Patient.where("name LIKE (?) AND gender = ?", 
      "%#{given_name} #{family_name}",params[:gender]).limit(20)

    render :layout => false
  end

end
