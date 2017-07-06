class Patient < BlisConnection
=begin
  before_save EncryptionWrapper.new("name"),
              EncryptionWrapper.new("email"),
              EncryptionWrapper.new("phone_number"),
              EncryptionWrapper.new("address")

  after_find EncryptionWrapper.new("name"),
             EncryptionWrapper.new("email"),
             EncryptionWrapper.new("phone_number"),
             EncryptionWrapper.new("address")
=end

  def age
    birthdate = self.dob.to_date rescue nil

    return [] if birthdate.blank?

    today = Date.today

    patient_age = (today.year - birthdate.year) + ((today.month - birthdate.month) + ((today.day - birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)
    age = []
   
    if ((today.year - birthdate.year) == 0) 
        patient_age =  today.month - birthdate.month
        if(patient_age<=6)
          age[0] = ""
          age[1] = ""
          age[2] = ""
          age[3] = " less 6ms old"
        else
          age[0] = ""
          age[1] = ""
          age[2] = ""
          age[3] = "less 12ms old"
        end

    elsif ((today.year -  birthdate.year) == 1)
        previous_yr_months = 12 - birthdate.month
        current_yr_months = today.month

        total_months = previous_yr_months + current_yr_months

        if (total_months>12)
          
            age[0] = total_months/12
            age[1] = "yrs"
            age[2] = ""
            age[3] = ""
          
        elsif (total_months<12)
            age[0] = ""
            age[1] = ""
            age[2] = total_months
            age[3] = "ms"
        end    
    else
    
      years = today.year - birthdate.year
      current_month = today.month
      birth_month = birthdate.month


      if (current_month>birth_month)
            age[0] = years
            age[1] = "yrs"
            age[2] = ""
            age[3] = " "
      elsif (current_month<birth_month)
            pre_months = 12 - birth_month
            age[0] = years - 1
            age[1] = "yrs"
            age[2] = ""
            age[3] = ""
      end 
    end

   return age   
         
  end

end
