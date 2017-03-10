def start

  patients = Patient.all
  patients.each_with_index do |p, i|
    name = p.name.strip.split(/\s+/) rescue next
    puts "#{(i + 1)}"

    first_name = name.first

    next if first_name.strip.blank?
    
    last_name = name.length > 1 ? name.last : ""

    p.first_name_code = first_name.soundex rescue nil
    p.last_name_code = last_name.soundex rescue nil
    p.save
  end
end

t = Time.now.to_s(:db)
puts "Starting batch encryption at #{Time.now.to_s(:db)}"
start
puts "Done"
puts "Started #{t}, Finished #{Time.now.to_s(:db)}"
