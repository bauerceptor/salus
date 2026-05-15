Rails.logger.debug "Seeding proactive agent test users..."

# dean.james@example.com -> James Dean (chronic liver disease patient)
james = User.find_or_create_by!(email: "dean.james@example.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.tos_agreement = true
end

unless james.account
  james.build_account(
    first_name: "James",
    last_name: "Dean",
    username: "james.dean",
    birthday: 30.years.ago,
    city: "London",
    country: "United Kingdom"
  )
  james.account.save!
end

james_account = james.account

# Create chronic liver disease for James Dean
liver_disease = PredefinedDisease.find_or_create_by(name: "chronic_liver_disease") do |pd|
  pd.description = "Chronic liver disease refers to a long-term condition where the liver is permanently damaged and cannot function properly."
  pd.icd10_code = "K76"
end

unless Disease.exists?(account: james_account, predefined_disease: liver_disease)
  Disease.create!(
    account: james_account,
    predefined_disease: liver_disease,
    name: "Chronic Liver Disease",
    severity: 3,
    color: "#e74c3c",
    status: "active",
    diagnosed_at: 2.years.ago
  )
end

# James's medications
unless james_account.medications.exists?(name: "Ursodeoxycholic Acid")
  med = Medication.create!(
    account: james_account,
    name: "Ursodeoxycholic Acid",
    dosage: "500mg",
    frequency: "twice_daily",
    instructions: "Take with food in the morning and evening.",
    is_active: true,
    reminder_enabled: true,
    source: "doctor_prescription"
  )

  # Morning schedule - one per day (day_of_week is a varchar string, not an array)
  %w[sunday monday tuesday wednesday thursday friday saturday].each do |day|
    med.medication_schedules.create!(
      scheduled_time: "08:00",
      day_of_week: day
    )
  end
end

unless james_account.medications.exists?(name: "Lactulose")
  med = Medication.create!(
    account: james_account,
    name: "Lactulose",
    dosage: "20g",
    frequency: "three_times_daily",
    instructions: "Take morning, afternoon, and evening.",
    is_active: true,
    reminder_enabled: true,
    source: "doctor_prescription"
  )

  %w[sunday monday tuesday wednesday thursday friday saturday].each do |day_name|
    [8, 14, 20].each do |hour|
      med.medication_schedules.create!(
        scheduled_time: "#{hour.to_s.rjust(2, '0')}:00",
        day_of_week: day_name
      )
    end
  end
end

# James's medication logs (last 14 days, some taken, some missed)
meds = james_account.medications.active
if meds.any?
  14.times do |days_ago|
    date = days_ago.days.ago.to_date
    meds.each do |med|
      next if med.medication_schedules.empty?

      med.medication_schedules.each do |schedule|
        next unless MedicationSchedule::DAYS_OF_WEEK[schedule.day_of_week.to_sym] == date.wday

        status = if days_ago > 3 && rand < 0.2
                    "missed"
                  elsif rand < 0.85
                    "taken"
                  else
                    "skipped"
                  end

        scheduled_time = date.change(hour: schedule.scheduled_time.hour, min: schedule.scheduled_time.min)

        MedicationLog.find_or_create_by(
          medication: med,
          account: james_account,
          scheduled_for: scheduled_time
        ) do |log|
          log.status = status
          log.taken_at = scheduled_time if status == "taken"
        end
      end
    end
  end
end

  # James's measurements (last 3 days - model validates measurement_date within 3 days)
  weight_type = MeasurementType.find_by(name: "weight")
  if weight_type
    3.times do |days_ago|
      date = (days_ago + 1).days.ago.to_date
    next if james_account.measurements.exists?(measurement_date: date, measurement_type: weight_type)

    james_account.measurements.create!(
      measurement_type: weight_type,
      value: (72.0 + rand * 4 - 2).round(1),
      measurement_date: date
    )
  end
end

# James's HealthAgent conversation (so the agentic messages have somewhere to go)
HealthAgentConversation.find_or_create_by!(
  account: james_account,
  persona: :patient
)

# smith.alan@salus.health -> Alan Smith (liver specialist)
alan = User.find_or_create_by!(email: "smith.alan@salus.health") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.tos_agreement = true
end

unless alan.specialist
  alan.build_specialist(
    field_of_expertise: "Gastroenterology",
    specialization: "hepatologist",
    specialization_description: "Specializes in liver diseases including chronic liver disease, cirrhosis, and hepatitis."
  )
  alan.set_specialist_role!
  alan.save!
end

unless alan.account
  alan.build_account(
    first_name: "Alan",
    last_name: "Smith",
    username: "alan.smith"
  )
  alan.account.save!
end

alan_account = alan.account

# Link Alan Smith as James Dean's specialist
# SpecialistPatient.specialist is a User, not a Specialist object
unless SpecialistPatient.exists?(specialist: alan, account: james_account)
  SpecialistPatient.create!(
    specialist: alan,
    account: james_account,
    relationship_type: "primary_care",
    status: "active"
  )
end

# admin@salus.com -> admin user (already exists via seeds.rb, but ensure it has the right password)
admin = AdminUser.find_or_create_by!(email: "admin@salus.com") do |au|
  au.password = "password"
  au.password_confirmation = "password"
end

Rails.logger.debug "Proactive agent test users seeded: James Dean (patient), Alan Smith (specialist), admin@salus.com (admin)"
