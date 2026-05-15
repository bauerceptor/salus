Rails.logger.debug "Seeding chat test users ..."

# Create a doctor (specialist) account - use find_or_create to avoid duplicates
doctor_user = User.find_or_create_by(email: "doctor@salus.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.tos_agreement = true
  u.build_specialist(
    field_of_expertise: "Cardiology",
    specialization: "cardiologist",
    specialization_description: "Heart specialist for testing chat"
  )
  u.set_specialist_role!
end

doctor_account = doctor_user.account || doctor_user.build_account(
  first_name: "Dr. Sarah",
  last_name: "Smith",
  username: "dr_smith"
)
doctor_account.save!

# Create a patient account - use find_or_create
patient_user = User.find_or_create_by(email: "patient@salus.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.tos_agreement = true
end

patient_account = patient_user.account || patient_user.build_account(
  first_name: "John",
  last_name: "Patient",
  username: "john_patient"
)
patient_account.save!

# Link patient to doctor for chat
SpecialistPatient.find_or_create_by(
  account_id: patient_account.id,
  specialist_id: doctor_user.id
) do |sp|
  sp.status = "active"
end

Rails.logger.debug "Chat test users created:"
Rails.logger.debug "  Doctor: doctor@salus.com / password"
Rails.logger.debug "  Patient: patient@salus.com / password"
Rails.logger.debug "Seeding chat test users completed."
