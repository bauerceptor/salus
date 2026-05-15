Rails.logger.debug "Creating dummy data..."

current_account = Account.first
current_account.user

# Add more users
users_data = [
  { email: "sarah.johnson@example.com", first_name: "Sarah", last_name: "Johnson" },
  { email: "dr.micheal@example.com", first_name: "Michael", last_name: "Smith" },
  { email: "emily.davis@example.com", first_name: "Emily", last_name: "Davis" },
  { email: "dr.james@example.com", first_name: "James", last_name: "Wilson" }
]

users_data.each do |user_data|
  next if User.find_by(email: user_data[:email])

  user = User.create!(
    email: user_data[:email],
    password: "password123",
    password_confirmation: "password123",
    tos_agreement: true,
    first_name: user_data[:first_name],
    last_name: user_data[:last_name]
  )

  Account.create!(
    user_id: user.id,
    email: user.email,
    first_name: user.first_name,
    last_name: user.last_name,
    username: user.email.split("@").first,
    city: "New York",
    country: "USA",
    education: "bachelor"
  )

  Rails.logger.debug { "Created user: #{user.email}" }
end

# Create medications
medications = [
  { name: "Metformin", dosage: "500mg", frequency: "Twice daily" },
  { name: "Lisinopril", dosage: "10mg", frequency: "Once daily" },
  { name: "Aspirin", dosage: "81mg", frequency: "Once daily" }
]

medications.each do |med|
  Medication.find_or_create_by(account: current_account, name: med[:name]) do |m|
    m.dosage = med[:dosage]
    m.frequency = med[:frequency]
    m.is_active = true
    m.start_date = 6.months.ago
  end
end
Rails.logger.debug "Created medications"

# Create notes
notes = [
  { title: "Doctor Appointment", content: "Follow up with cardiologist next month", note_type: "appointment" },
  { title: "Medication Reminder", content: "Remember to take Metformin with food", note_type: "reminder" },
  { title: "Health Goal", content: "Lose 10 pounds by summer", note_type: "goal" },
  { title: "Weekly Exercise", content: "Exercise 3 times per week", note_type: "goal" },
  { title: "Diet Plan", content: "Eat more vegetables and fruits", note_type: "general" }
]

notes.each do |note|
  Note.find_or_create_by(account: current_account, title: note[:title]) do |n|
    n.content = note[:content]
    n.note_type = note[:note_type]
    n.is_pinned = [true, false].sample
    n.background_color = ""
  end
end
Rails.logger.debug "Created notes"

# Create emergency contacts
EmergencyContact.find_or_create_by(account: current_account, name: "John Doe") do |ec|
  ec.phone_number = "+1-555-0100"
  ec.relationship = "Spouse"
  ec.is_primary = true
end
Rails.logger.debug "Created emergency contacts"

# Create notifications
5.times do |i|
  Notification.find_or_create_by(
    account: current_account,
    title: "Sample Notification #{i + 1}"
  ) do |n|
    n.body = "This is a sample notification body for testing purposes."
    n.notification_type = "general"
    n.read_at = i.even? ? Time.current : nil
  end
end
Rails.logger.debug "Created notifications"

# Create friendships with other accounts
other_accounts = Account.where.not(id: current_account.id).limit(2)
if other_accounts.any?
  Friendship.find_or_create_by(account: current_account, friend: other_accounts.first) do |f|
    f.status = "accepted"
  end
  Friendship.find_or_create_by(account: other_accounts.first, friend: current_account) do |f|
    f.status = "accepted"
  end
  Rails.logger.debug "Created friendships"
end

# Create measurement types if not exist
weight_type = MeasurementType.find_or_create_by(name: "weight") do |mt|
  mt.unit = "kg"
  mt.lower_limit = "50"
  mt.upper_limit = "150"
end

sugar_type = MeasurementType.find_or_create_by(name: "sugar") do |mt|
  mt.unit = "mg/dL"
  mt.lower_limit = "70"
  mt.upper_limit = "99"
end

MeasurementType.find_or_create_by(name: "blood_pressure") do |mt|
  mt.unit = "mmHg"
  mt.lower_limit = "90/60"
  mt.upper_limit = "120/80"
end

MeasurementType.find_or_create_by(name: "heart_beat") do |mt|
  mt.unit = "bpm"
  mt.lower_limit = "60"
  mt.upper_limit = "100"
end
Rails.logger.debug "Created measurement types"

# Create measurements for past 30 days
30.times do |i|
  begin
    Measurement.create(
      account: current_account,
      measurement_type: weight_type,
      measurement_date: i.days.ago.to_date,
      value: (70 + (rand * 5)).round(1)
    )
  rescue StandardError
    nil
  end

  begin
    Measurement.create(
      account: current_account,
      measurement_type: sugar_type,
      measurement_date: i.days.ago.to_date,
      value: (90 + (rand * 20)).round(0)
    )
  rescue StandardError
    nil
  end
end
Rails.logger.debug "Created measurements"

Rails.logger.debug "\n=== Dummy Data Summary ==="
Rails.logger.debug { "Users: #{User.count}" }
Rails.logger.debug { "Accounts: #{Account.count}" }
Rails.logger.debug { "Medications: #{Medication.count}" }
Rails.logger.debug { "Notes: #{Note.count}" }
Rails.logger.debug { "Notifications: #{Notification.count}" }
Rails.logger.debug { "Measurements: #{Measurement.count}" }
Rails.logger.debug { "Emergency Contacts: #{EmergencyContact.count}" }
Rails.logger.debug { "Friendships: #{Friendship.count}" }
Rails.logger.debug "========================="
