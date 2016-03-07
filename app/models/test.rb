class Test < ActiveRecord::Base
  self.table_name = "tests"
  
  belongs_to :test_type, class_name: 'TestType', foreign_key: "test_type_id"
  belongs_to :visit, class_name: 'Visit', foreign_key: "visit_id"
  belongs_to :specimen, class_name: 'Specimen', foreign_key: "specimen_id"
  belongs_to :status, class_name: 'TestStatus', foreign_key: "test_status_id"
  has_many :test_results, class_name: 'TestResult', foreign_key: "test_id"

  def name
    self.test_type.name rescue nil
  end
  def short_name
    self.test_type.short_name rescue nil
  end
  def self.supported?(test_types = [])
    test_types.each do |tname|
      return false if (TestType.find_by_name(tname).blank? && PanelType.find_by_name(tname).blank?)
    end
    return true
  end
end
