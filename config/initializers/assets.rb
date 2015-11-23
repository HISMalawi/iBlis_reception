# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'
=begin
Rails.application.config.assets.precompile += %w( bootstrap-3.3.5-dist/* )
Rails.application.config.assets.precompile += %w( footer.sticky.css )
Rails.application.config.assets.precompile += %w( patient/* )
Rails.application.config.assets.precompile += %w( person/* )
Rails.application.config.assets.precompile += %w( DrCalendar/* )
Rails.application.config.assets.precompile += %w( placeholder.js )
Rails.application.config.assets.precompile += %w( invoke_placeholder.js )
Rails.application.config.assets.precompile += %w( DataTables/* )
Rails.application.config.assets.precompile += %w( autoComplete/* )
Rails.application.config.assets.precompile += %w( Diagnosis/* )
=end

Rails.application.config.assets.precompile += %w( extras/*)


# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
# Rails.application.config.assets.precompile += %w( search.js )
