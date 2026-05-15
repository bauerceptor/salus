Rails.logger.debug "Creating comprehensive dummy data for testing dashboards..."

# Get accounts using raw SQL to avoid JSON column issues
account_ids = ActiveRecord::Base.connection.select_all(
  "SELECT id FROM accounts LIMIT 20"
).pluck("id")

accounts = Account.where(id: account_ids)

# Create measurement types first (idempotent - won't create duplicates)
measurement_types_data = [
  { name: "weight", unit: "kg", lower_limit: "40", upper_limit: "150" },
  { name: "blood_pressure", unit: "mmHg", lower_limit: "90/60", upper_limit: "140/90" },
  { name: "heart_beat", unit: "bpm", lower_limit: "60", upper_limit: "100" },
  { name: "sugar", unit: "mg/dL", lower_limit: "70", upper_limit: "140" },
  { name: "spo2", unit: "%", lower_limit: "90", upper_limit: "100" }
]

measurement_types = measurement_types_data.map do |data|
  MeasurementType.find_or_create_by(name: data[:name]) do |mt|
    mt.unit = data[:unit]
    mt.lower_limit = data[:lower_limit]
    mt.upper_limit = data[:upper_limit]
  end
end

accounts.each do |account|
  Rails.logger.debug { "Seeding data for: #{account.full_name}" }

  # Add diseases if not exist
  if account.diseases.count < 2
    predefined = PredefinedDisease.first(3)
    predefined.each do |pd|
      account.diseases.find_or_create_by(predefined_disease: pd) do |d|
        d.name = pd.name.titleize
        d.severity = [1, 2, 3, 4, 5].sample
        d.color = "#FF#{rand(16..99)}#{rand(16..99)}"
        d.status = "active"
        d.diagnosed_at = rand(1..24).months.ago
      end
    end
  end

  # Add treatments
  2.times do |i|
    Treatment.find_or_create_by(account: account, name: "Treatment #{i + 1} for #{account.full_name}") do |t|
      t.description = "Treatment plan for #{account.full_name}"
      t.status = %w[active completed pending].sample
      t.start_date = rand(1..6).months.ago
    end
  end

  # Add medications
  medications_data = [
    { name: "Aspirin", dosage: "81mg", frequency: "Once daily" },
    { name: "Metformin", dosage: "500mg", frequency: "Twice daily" },
    { name: "Lisinopril", dosage: "10mg", frequency: "Once daily" },
    { name: "Vitamin D", dosage: "1000IU", frequency: "Once daily" }
  ]
  medications_data.sample(3).each do |med|
    Medication.find_or_create_by(account: account, name: med[:name]) do |m|
      m.dosage = med[:dosage]
      m.frequency = med[:frequency]
      m.is_active = true
      m.start_date = rand(1..12).months.ago
    end
  end

  # Add measurements (30 days of health monitoring data)
  measurement_types.each do |mt|
    30.times do |i|
      value = case mt.name
              when "weight" then (60 + (rand * 20)).round(1)
              when "blood_pressure" then "#{rand(100..140)}/#{rand(60..90)}"
              when "heart_beat" then rand(60..100)
              when "sugar" then (80 + (rand * 40)).round(0)
              else rand(100)
              end

      Measurement.find_or_create_by(
        account: account,
        measurement_type: mt,
        measurement_date: i.days.ago.to_date
      ) do |m|
        m.value = value
      end
    end
  end

  # Add notes
  notes_data = [
    { title: "Doctor Appointment", content: "Follow up with cardiologist next month", note_type: "appointment" },
    { title: "Medication Reminder", content: "Remember to take medication with food", note_type: "reminder" },
    { title: "Health Goal", content: "Lose 10 pounds by summer", note_type: "goal" },
    { title: "Lab Results", content: "All values within normal range", note_type: "medical" },
    { title: "Weekly Exercise", content: "Exercise 3 times per week", note_type: "goal" },
    { title: "Diet Plan", content: "Eat more vegetables and fruits", note_type: "general" }
  ]
  notes_data.each do |note|
    Note.find_or_create_by(account: account, title: note[:title]) do |n|
      n.content = note[:content]
      n.note_type = note[:note_type]
      n.is_pinned = [true, false].sample
    end
  end

  # Add notifications
  5.times do |i|
    Notification.find_or_create_by(account: account, title: "Notification #{i + 1} - #{account.full_name}") do |n|
      n.body = "This is a sample notification. Please review your health data."
      n.notification_type = %w[general medication_reminder appointment_reminder].sample
      n.read_at = i.even? ? Time.current : nil
    end
  end

  # Add disease statuses
  if account.diseases.any?
    disease = account.diseases.first
    3.times do |_i|
      DiseaseStatus.create!(
        disease: disease,
        status: %w[diagnosed improvement deterioration].sample,
        content: "Status update for #{account.full_name}",
        mood: [1, 2, 3].sample
      )
    end
  end

  Rails.logger.debug { "  Done: #{account.full_name}" }
end

# Add specialist patient relationships and recommendations
specialists = User.joins(:roles).where(roles: { name: "specialist" }).limit(5)
specialists.each do |specialist|
  next unless specialist.specialist

  patients = Account.where.not(user_id: specialists.select(:id)).limit(10)

  patients.each do |patient|
    SpecialistPatient.find_or_create_by(specialist: specialist, account: patient) do |sp|
      sp.status = "active"
      sp.relationship_type = "consulting"
    end

    SpecialistRecommendation.find_or_create_by(
      specialist: specialist,
      account: patient,
      name: "Recommendation for #{patient.full_name}"
    ) do |sr|
      sr.recommendation_type = %w[medication lifestyle treatment].sample
      sr.dosage = "Standard dosage"
      sr.status = "pending"
      sr.notes = "Please review this recommendation"
    end

    SpecialistNote.find_or_create_by(
      specialist: specialist,
      account: patient,
      content: "Patient notes for #{patient.full_name}"
    ) do |sn|
      sn.note_type = "observation"
    end
  end

  Rails.logger.debug { "Added data for specialist: #{specialist.email}" }
end

# Add specialist requests
patients = Account.where.not(user_id: specialists.select(:id)).limit(10)
patients.each do |patient|
  next if patient.specialist_requests.any?

  SpecialistRequest.create!(
    account: patient,
    specialist_id: specialists.sample.id,
    status: %w[pending approved rejected].sample
  )
end

Rails.logger.debug "\n=== Comprehensive Data Seeding Complete ==="
Rails.logger.debug { "Accounts processed: #{accounts.count}" }
Rails.logger.debug { "Diseases: #{Disease.count}" }
Rails.logger.debug { "Treatments: #{Treatment.count}" }
Rails.logger.debug { "Medications: #{Medication.count}" }
Rails.logger.debug { "Medication Schedules: #{MedicationSchedule.count}" }
Rails.logger.debug { "Measurements: #{Measurement.count}" }
Rails.logger.debug { "Notes: #{Note.count}" }
Rails.logger.debug { "Notifications: #{Notification.count}" }
Rails.logger.debug { "Emergency Contacts: #{EmergencyContact.count}" }
Rails.logger.debug { "Disease Statuses: #{DiseaseStatus.count}" }
Rails.logger.debug { "Specialist Patients: #{SpecialistPatient.count}" }
Rails.logger.debug { "Specialist Recommendations: #{SpecialistRecommendation.count}" }
Rails.logger.debug { "Specialist Notes: #{SpecialistNote.count}" }
Rails.logger.debug { "Specialist Requests: #{SpecialistRequest.count}" }
Rails.logger.debug "==========================================="
