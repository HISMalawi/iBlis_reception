class TestResult < ActiveRecord::Base
  self.table_name = "test_results"

  belongs_to :test, class_name: 'Test', foreign_key: 'id'
end
