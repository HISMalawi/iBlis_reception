
def start

  patients =
ActiveRecord::Base.connection.select_all <<EOF
SELECT * FROM patients LIMIT 90000000000000
EOF
  file = File.new("results.csv", "w")
  file << "name | E_name, Phone# | E_Phone# | Email | E_Email | Address| E_Address"
  patients.each_with_index do |patient, i|
    nameA, numA, emailA, addressA = [patient['name'], patient['phone_number'], patient['email'], patient['address']]
    puts "Working on patient #{(i + 1)} patient_number : #{patient['patient_number']}"
    p = Patient.find(patient['id'])
    p.name = nameA
    p.phone_number = numA
    p.email = emailA
    p.address = addressA
    p.save
    p =
        ActiveRecord::Base.connection.select_all <<EOF
SELECT * FROM patients WHERE patient_number = #{patient['patient_number']}
EOF
    p = p.first
    nameB, numB, emailB, addressB = [p['name'], p['phone_number'], p['email'], p['address']]
    file << "\n#{nameA} | #{nameB} | #{numA}, #{numB} | #{emailA} | #{emailB} | #{addressA} | #{addressB}"
  end
end
t = Time.now.to_s(:db)
puts "Starting batch encryption at #{Time.now.to_s(:db)}"
start
puts "Done"
puts "Started #{t}, Finished #{Time.now.to_s(:db)}"
