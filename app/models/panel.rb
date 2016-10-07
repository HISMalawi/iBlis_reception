class Panel < BlisConnection
  self.table_name = "panels"

  belongs_to :panel_type, class_name: "PanelType", foreign_key: "panel_type_id"
  
	def self.disambiguate(test_types) 
		to_negate = []
		panels = []
		test_types.each do |type|
			panel = PanelType.where(:name => type).first
			if(panel)
				panels << panel.name
				to_negate += Panel.joins(' INNER JOIN test_types ON test_types.id = panels.test_type_id ')
					.where(:panel_type_id => panel.id)
					.select('test_types.name').map(&:name)
			end
		end 

		(panels + test_types - to_negate).uniq
	end
end
