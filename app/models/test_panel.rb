class TestPanel < ActiveRecord::Base
  self.table_name = "test_panels"
  belongs_to :panel_type, class_name: 'PanelType', foreign_key: "panel_type_id"

end
