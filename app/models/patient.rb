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

  def self.create_from_scan(segments)

    patient = self.find_by_external_patient_number(segments[1])
    if patient.blank?
      patient = self.create(
        :name 		=> segments[0].gsub("^", " ").gsub(/\s+/, " "),
        :first_name_code => (segments[0].split("^")[0].soundex rescue ""),
        :last_name_code  => (segments[0].split("^")[2].soundex rescue ""),
        :created_by			=> User.current.id,
        :address				=> nil,
        :phone_number		=> nil,
        :gender					=> 	segments[2],
        :patient_number => 	(Patient.count + 1),
        :dob => Time.at(segments[3]).to_date,
        :dob_estimated => 0,
        :external_patient_number => segments[1])
    end

    patient
  end
end
