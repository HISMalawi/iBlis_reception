class Patient < BlisConnection

  before_save EncryptionWrapper.new("name"),
              EncryptionWrapper.new("email"),
              EncryptionWrapper.new("phone_number"),
              EncryptionWrapper.new("address")

  after_find EncryptionWrapper.new("name"),
             EncryptionWrapper.new("email"),
             EncryptionWrapper.new("phone_number"),
             EncryptionWrapper.new("address")

  def age
    birthdate = self.dob.to_date ; today = Date.today

    patient_age = (today.year - birthdate.year) + ((today.month - birthdate.month) + ((today.day - birthdate.day) < 0 ? -1 : 0) < 0 ? -1 : 0)
   
    birth_date = self.dob
    estimate= self.dob_estimated

    if birth_date.month == 7 and birth_date.day == 15 and estimate == 1 and Time.now.month < birth_date.month and self.created_at.to_date.year == Time.now.year
       return patient_age + 1
    else
       return patient_age
    end     
  end

end
