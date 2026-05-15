Rails.logger.debug "Adding remaining data..."

current_account = Account.first
current_account.user

# Create liver diseases for current account
hepatitis_b = PredefinedDisease.find_by(name: "hepatitis_b")
nafld = PredefinedDisease.find_by(name: "nafld")

# Create user's liver diseases
if hepatitis_b
  begin
    Disease.create!(
      account: current_account,
      predefined_disease: hepatitis_b,
      name: "Hepatitis B",
      description: "Chronic hepatitis B infection",
      severity: "moderate",
      status: "active",
      diagnosed_date: 2.years.ago,
      color: "#e74c3c"
    )
    Rails.logger.debug "Created Hepatitis B disease"
  rescue StandardError
    Rails.logger.debug "Disease hepatitis_b may already exist"
  end
end

if nafld
  begin
    Disease.create!(
      account: current_account,
      predefined_disease: nafld,
      name: "NAFLD",
      description: "Non-alcoholic fatty liver disease",
      severity: "mild",
      status: "active",
      diagnosed_date: 1.year.ago,
      color: "#f39c12"
    )
    Rails.logger.debug "Created NAFLD disease"
  rescue StandardError
    Rails.logger.debug "Disease nafld may already exist"
  end
end
Rails.logger.debug "Done with diseases"

# Create specialist for a doctor user
dr_user = User.find_by(email: "dr.micheal@example.com")
if dr_user
  begin
    Specialist.create!(
      user: dr_user,
      field_of_expertise: "Hepatology",
      specialization: "Viral Hepatitis",
      specialization_description: "Treatment of hepatitis B and C",
      license_number: "MD-12345",
      status: "active"
    )
    Rails.logger.debug "Created specialist for dr.micheal"
  rescue StandardError => e
    Rails.logger.debug { "Specialist error: #{e.message[0..100]}" }
  end
end
Rails.logger.debug "Done with specialists"

# Get the specialist
specialist = Specialist.first
if specialist && current_account
  begin
    SpecialistPatient.create!(
      specialist: specialist,
      account: current_account,
      status: "active",
      relationship_type: "consulting",
      notes: "Patient with chronic hepatitis B"
    )
    Rails.logger.debug "Created specialist patient"
  rescue StandardError => e
    Rails.logger.debug { "SpecialistPatient error: #{e.message[0..100]}" }
  end

  begin
    SpecialistRecommendation.create!(
      specialist: specialist,
      account: current_account,
      recommendation_type: "medication",
      name: "Entecavir",
      dosage: "0.5mg once daily",
      status: "pending",
      notes: "Take on empty stomach"
    )
    Rails.logger.debug "Created recommendation 1"
  rescue StandardError => e
    Rails.logger.debug { "Recommendation 1 error: #{e.message[0..100]}" }
  end

  begin
    SpecialistRecommendation.create!(
      specialist: specialist,
      account: current_account,
      recommendation_type: "lifestyle",
      name: "Diet Modification",
      dosage: "N/A",
      status: "pending",
      notes: "Low fat diet, avoid alcohol"
    )
    Rails.logger.debug "Created recommendation 2"
  rescue StandardError => e
    Rails.logger.debug { "Recommendation 2 error: #{e.message[0..100]}" }
  end

  begin
    SpecialistNote.create!(
      specialist: specialist,
      account: current_account,
      content: "Patient is responding well to treatment. Continue with current medication.",
      note_type: "observation"
    )
    Rails.logger.debug "Created specialist note"
  rescue StandardError => e
    Rails.logger.debug { "Note error: #{e.message[0..100]}" }
  end
end
Rails.logger.debug "Done with specialist data"

# Create treatment
begin
  Treatment.create!(
    account: current_account,
    name: "Hepatitis B Management",
    description: "Comprehensive treatment plan for chronic Hepatitis B",
    status: "active",
    start_date: 6.months.ago
  )
  Rails.logger.debug "Created treatment"
rescue StandardError => e
  Rails.logger.debug { "Treatment error: #{e.message[0..100]}" }
end

Rails.logger.debug "\n=== Final Data Summary ==="
Rails.logger.debug { "Diseases: #{Disease.count}" }
Rails.logger.debug { "Specialists: #{Specialist.count}" }
Rails.logger.debug { "Specialist Patients: #{SpecialistPatient.count}" }
Rails.logger.debug { "Specialist Recommendations: #{SpecialistRecommendation.count}" }
Rails.logger.debug { "Specialist Notes: #{SpecialistNote.count}" }
Rails.logger.debug { "Treatments: #{Treatment.count}" }
Rails.logger.debug "================================="
