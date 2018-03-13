
ActiveRecord::Base.establish_connection(
    Rails.configuration.database_configuration["#{Rails.env}"].inject({}){|h, v|
      h[v.first] = (v.last.to_s.length > 40 ? EncryptionWrapper.humanize(v.last) : v.last); h
    })

def start(s_date, e_date)
drugs = []
  file = File.new("results.csv", "w")
  file << "#|AccessionNumber | Name | DOB | Age | Gender | Ward | Sample Type | Gram | Culture | Organism | Drugs | Zone Size| Interpretation "

 data =
     ActiveRecord::Base.connection.select_all <<EOF
SELECT
	s.accession_number,
	p.id patient_id,
  dob,
  (TIMESTAMPDIFF(YEAR, dob, v.created_at)) age,
	gender,
  v.ward_or_location, t.id test_id,
	(SELECT name FROM specimen_types WHERE id = s.specimen_type_id) sample_type,
	(SELECT name FROM test_types WHERE id = t.test_type_id) test_type,
	(SELECT name FROM measures WHERE id = r.measure_id) result_name,
	r.result,
  (SELECT result FROM test_results WHERE test_id  IN
    (SELECT id FROM tests WHERE specimen_id = s.id )
			AND measure_id = (SELECT id FROM measures WHERE name = 'Gram') ORDER BY id DESC LIMIT 1
  ) gram
FROM patients p
	INNER JOIN visits v ON v.patient_id = p.id
	INNER JOIN tests t ON t.visit_id = v.id
	INNER JOIN specimens s ON t.specimen_id = s.id
	INNER JOIN test_results r ON r.test_id = t.id AND r.measure_id IN (SELECT id FROM measures WHERE name = 'Culture')
WHERE t.test_type_id = (SELECT id from test_types WHERE name = 'Culture & Sensitivity')
GROUP BY tracking_number LIMIT 1000000000000000000;
EOF

  data.each_with_index do |order, i|
    gender = order['gender'].to_i == 0 ? 'M' : 'F'
    patient_name = Patient.find(order['patient_id']).name
    gram = order['gram'] == '0' ? '' : order['gram']
    result = order['result'] == '0' ? '' : order['result']

		#next if result.downcase.strip != "growth" || gram != "Gram negative bacilli"

    file << "\n#{(i + 1).to_s}|#{order['accession_number']} | #{patient_name} | #{order['dob']} | #{order['age'].to_s} | #{gender} | #{order['ward_or_location']}" +
          "| #{order['sample_type']} |#{gram}| #{result}||||"
		


    organisms =
        ActiveRecord::Base.connection.select_all <<EOF
SELECT (SELECT name FROM organisms WHERE id = ds.organism_id) name,
      (SELECT name FROM drugs WHERE id = ds.drug_id) drug, ds.zone, ds.interpretation FROM drug_susceptibility ds WHERE test_id = #{order['test_id']}
      AND deleted_at IS NULL
;
EOF

    organisms.each do |ds|
      next if ds['interpretation'].blank?
      next if ds['name'].blank?
      next if ds['drug'].blank?

      interp = ds['interpretation'].to_s.force_encoding("UTF-8")
      drug = ds['drug'].to_s.force_encoding("UTF-8")
      name = ds['name'].to_s.force_encoding("UTF-8")
      zone = ds['zone'].to_s.force_encoding("UTF-8")

			drugs << drug			
		
      file << "\n | |  |  |  |  |  |  |  |  | #{name} | #{drug} |#{zone} | #{interp}"
    end
  end

#raise drugs.uniq.inspect
end

cmd = ARGV
start_date = cmd.first || "01-01-1900".to_date
end_date = cmd.last || Date.today

start(start_date, end_date)
