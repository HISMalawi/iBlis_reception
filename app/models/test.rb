class Test < ActiveRecord::Base
  self.table_name = "tests"
  
  belongs_to :test_type, class_name: 'TestType', foreign_key: "test_type_id"
  belongs_to :visit, class_name: 'Visit', foreign_key: "visit_id"
  belongs_to :specimen, class_name: 'Specimen', foreign_key: "specimen_id"
  belongs_to :status, class_name: 'TestStatus', foreign_key: "test_status_id"
  
end
