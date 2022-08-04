require 'io/console'

settings = YAML.load_file("#{Rails.root}/config/application.yml")
configs = YAML.load_file "#{Rails.root}/config/nlims_connection.yml"
count = Patient.find_by_sql("SELECT count(*) AS count_r FROM patients")
counter = count[0]['count_r']
while counter > 0
   
    res = Patient.find_by(id: counter)    
    res.name = "Test Patient #{counter}"
    res.save();
    counter  = counter - 1
    puts "de-identyfing patient number #{counter} in reverse order"
end

puts "finish processing"
