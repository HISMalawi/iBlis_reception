#load Organisms Into In App

CSV.foreach("#{Rails.root}/app/assets/data/health_facilities.csv", :headers => true) do |row|
  
end