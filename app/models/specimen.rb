class Specimen < BlisConnection
  self.table_name = "specimens"

  belongs_to :specimen_type, class_name: 'SpecimenType', foreign_key: "specimen_type_id"
  belongs_to :status, class_name: "SpecimenStatus", foreign_key: "specimen_status_id"
	has_many :tests, class_name: "Test", foreign_key: "specimen_id"
end
