Rails.logger.debug "Seeding English version..."

# Order is important
load Rails.root.join("db", "seeds", "en", "roles.rb")
load Rails.root.join("db", "seeds", "en", "predefined_diseases.rb")
load Rails.root.join("db", "seeds", "en", "predefined_symptomps.rb")
load Rails.root.join("db", "seeds", "en", "units.rb")
load Rails.root.join("db", "seeds", "en", "measurement_types.rb")
load Rails.root.join("db", "seeds", "en", "article_tags.rb")

# Seeds for local development
if Rails.env.development?
  load Rails.root.join("db", "seeds", "en", "random_users.rb")
  load Rails.root.join("db", "seeds", "en", "specialists.rb")
  load Rails.root.join("db", "seeds", "en", "chat_test_users.rb")
  load Rails.root.join("db", "seeds", "en", "proactive_seeds.rb")
end

# Admin user for admin dashboard
AdminUser.find_or_create_by!(email: "admin@example.com") do |au|
  au.password = "password"
  au.password_confirmation = "password"
end

Rails.logger.debug "Seeding done."
