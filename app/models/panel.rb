class Panel < ActiveRecord::Base
  self.table_name = "panels"

  belongs_to :panel_type, class_name: "PanelType", foreign_key: "panel_type_id"
  
end
