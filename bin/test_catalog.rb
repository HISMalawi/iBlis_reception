catalog = {}

specimen_types = SpecimenType.all

specimen_types.each do |specimen|
  next if !specimen.deleted_at.blank?

  TestTypeSpecimenType.where(:specimen_type_id => specimen.id).each do |st|

    test = TestType.find(st.test_type_id)
    next if !test.deleted_at.blank?

    catalog[specimen.name] = [] if catalog[specimen.name].blank?
    catalog[specimen.name] << test.name
  end
end

File.open("test_catalog.json","w") do |f|
  f.write(catalog.to_json)
end