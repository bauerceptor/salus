Rails.logger.debug "Seeding complete patient data for testing..."

# Get patient account
patient = Account.joins(:user).where(users: { email: "patient@salus.com" }).first

unless patient
  Rails.logger.debug "ERROR: Patient account not found!"
  exit 1
end

Rails.logger.debug { "Seeding data for patient: #{patient.full_name}" }

# Ensure patient has diseases
if patient.diseases.count < 2
  predefined = PredefinedDisease.first(5)
  predefined.each do |pd|
    patient.diseases.find_or_create_by(predefined_disease: pd) do |d|
      d.name = pd.name.titleize
      d.severity = [1, 2, 3, 4, 5].sample
      d.color = "#FF#{rand(16..99)}#{rand(16..99)}"
      d.status = "active"
      d.diagnosed_at = rand(1..12).months.ago
    end
  end
end

Rails.logger.debug { "  Diseases: #{patient.diseases.count}" }

# Create DiseaseStatus posts for patient (visible in feed)
disease = patient.diseases.first
if disease
  10.times do |i|
    DiseaseStatus.find_or_create_by(
      disease: disease,
      created_at: i.days.ago
    ) do |ds|
      ds.status = %w[diagnosed improvement deterioration].sample
      ds.content = ["Feeling much better today!", "Had a tough day health-wise.", "Great progress on treatment!", "Noticing some improvements.", "Health is stable."].sample
      ds.mood = [1, 2, 3].sample
      ds.hidden = false
    end
  end
end

Rails.logger.debug { "  Disease statuses: #{DiseaseStatus.where(disease_id: patient.diseases.pluck(:id)).count}" }

# Create measurements for patient (30 days of data for each type)
measurement_types = MeasurementType.all
measurement_types.each do |mt|
  30.times do |i|
    value = case mt.name
            when "weight" then (65 + (rand * 15)).round(1)
            when "blood_pressure" then "#{rand(100..140)}/#{rand(60..90)}"
            when "heart_beat" then rand(60..100)
            when "sugar" then (90 + (rand * 50)).round(0)
            when "spo2" then (95 + (rand * 5)).round(0)
            else rand(100)
            end

    patient.measurements.find_or_create_by(
      measurement_type: mt,
      measurement_date: i.days.ago.to_date
    ) do |m|
      m.value = value
    end
  end
end

Rails.logger.debug { "  Measurements: #{patient.measurements.count}" }

# Create notes for patient
notes_data = [
  { title: "Doctor Appointment", content: "Follow up with cardiologist next week", note_type: "appointment" },
  { title: "Medication Reminder", content: "Take Metformin with breakfast", note_type: "reminder" },
  { title: "Health Goal", content: "Lose 10 pounds by summer", note_type: "goal" },
  { title: "Lab Results", content: "All values within normal range", note_type: "medical" },
  { title: "Exercise Plan", content: "Walk 30 minutes daily", note_type: "general" }
]

notes_data.each do |note_data|
  patient.notes.find_or_create_by(title: note_data[:title]) do |n|
    n.content = note_data[:content]
    n.note_type = note_data[:note_type]
    n.is_pinned = [true, false].sample
  end
end

Rails.logger.debug { "  Notes: #{patient.notes.count}" }

# Create medications for patient
medications_data = [
  { name: "Metformin", dosage: "500mg", frequency: "Twice daily" },
  { name: "Lisinopril", dosage: "10mg", frequency: "Once daily" },
  { name: "Aspirin", dosage: "81mg", frequency: "Once daily" }
]

medications_data.each do |med_data|
  patient.medications.find_or_create_by(name: med_data[:name]) do |m|
    m.dosage = med_data[:dosage]
    m.frequency = med_data[:frequency]
    m.is_active = true
    m.start_date = rand(1..6).months.ago
  end
end

Rails.logger.debug { "  Medications: #{patient.medications.count}" }

# Create notifications for patient
5.times do |i|
  patient.notifications.find_or_create_by(title: "Notification #{i + 1}") do |n|
    n.body = "This is a health notification for #{patient.full_name}"
    n.notification_type = %w[general medication_reminder appointment_reminder].sample
    n.read_at = i.even? ? Time.current : nil
  end
end

Rails.logger.debug { "  Notifications: #{patient.notifications.count}" }

status_count = DiseaseStatus.where(disease_id: patient.diseases.pluck(:id)).count

Rails.logger.debug "\nPatient data seeding complete!"
Rails.logger.debug "Patient now has:"
Rails.logger.debug { "  - #{patient.diseases.count} diseases" }
Rails.logger.debug { "  - #{status_count} status posts (visible in feed)" }
Rails.logger.debug { "  - #{patient.measurements.count} measurements" }
Rails.logger.debug { "  - #{patient.notes.count} notes" }
Rails.logger.debug { "  - #{patient.medications.count} medications" }
Rails.logger.debug { "  - #{patient.notifications.count} notifications" }
Rails.logger.debug { "  - #{patient.friends.count} friends" }
