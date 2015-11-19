class Visit < ActiveRecord::Base
  self.table_name = "visits"

  belongs_to :patient, class_name: 'Patient', foreign_key: 'patient_id'
end
