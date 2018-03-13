  if defined?(ActiveRecord::Base)

    ActiveRecord::Base.establish_connection(
        Rails.configuration.database_configuration["#{Rails.env}"].inject({}){|h, v|
          h[v.first] = (v.last.to_s.length > 40 ? EncryptionWrapper.humanize(v.last) : v.last); h
        })
  end