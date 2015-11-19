class VisitTypeWard < ActiveRecord::Base
  self.table_name = "visittype_wards"

  belongs_to :ward, class_name: 'Ward', foreign_key: 'ward_id'
  belongs_to :visit_type, class_name: 'VisitType', foreign_key: 'visit_type_id'
end
