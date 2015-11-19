class Patient < ActiveRecord::Base

  def age
    birthdate = self.dob ; today = Date.today

    patient_age = (today.year - birthdate.year) + ((today.month - birthdate.month) + ((today.day - birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)
   
    birth_date = self.dob
    estimate= 0 #self.birthdate_estimated

    if birth_date.month == 7 and birth_date.day == 1 and estimate == 1 and Time.now.month < birth_date.month and self.created_at.year == Time.now.year
       return patient_age + 1
    else
       return patient_age
    end     
  end

end
