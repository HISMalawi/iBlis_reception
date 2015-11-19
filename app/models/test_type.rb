class TestType < ActiveRecord::Base
  self.table_name = "test_types"

  belongs_to :test_category, class_name: 'TestCategory', foreign_key: 'test_category_id'
end
