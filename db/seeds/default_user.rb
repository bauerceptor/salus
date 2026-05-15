# frozen_string_literal: true

Rails.logger.debug "Seeding default user..."

# Create default user
user = User.find_or_initialize_by(email: "john.doe@gmail.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.tos_agreement = true
end

if user.save
  Rails.logger.debug { "Default user created: #{user.email}" }
else
  Rails.logger.warn "Default user could not be created: #{user.errors.full_messages.join(', ')}"
end

# Ensure patient role exists
patient_role = Role.find_or_create_by!(name: "patient") do |_r|
  Rails.logger.debug "Created patient role"
end

Role.find_or_create_by!(name: "specialist") do |_r|
  Rails.logger.debug "Created specialist role"
end

# Assign patient role to default user
unless user.roles.include?(patient_role)
  user.roles << patient_role
  Rails.logger.debug { "Assigned patient role to #{user.email}" }
end

# Create default account
account = Account.find_or_initialize_by(user: user) do |a|
  a.first_name = "John"
  a.last_name = "Doe"
  a.username = "john.doe"
end

if account.save
  Rails.logger.debug { "Account created for #{user.email}" }
else
  Rails.logger.warn "Account could not be created: #{account.errors.full_messages.join(', ')}"
end

Rails.logger.debug "Default user seeding complete!"
