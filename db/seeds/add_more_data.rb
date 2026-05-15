Rails.logger.debug "Adding more comprehensive data..."

current_account = Account.first
current_account.user

# Create liver-related predefined diseases
liver_diseases = [
  { name: "hepatitis_b", description: "Hepatitis B is a liver infection caused by the hepatitis B virus (HBV).", icd10_code: "B16" },
  { name: "hepatitis_c", description: "Hepatitis C is a liver infection caused by the hepatitis C virus (HCV).", icd10_code: "B17" },
  { name: "cirrhosis", description: "Cirrhosis is a late stage of progressive liver fibrosis.", icd10_code: "K74" },
  { name: "nafld", description: "Non-alcoholic fatty liver disease (NAFLD).", icd10_code: "K76" },
  { name: "nash", description: "Non-alcoholic steatohepatitis (NASH).", icd10_code: "K75" },
  { name: "liver_cancer", description: "Liver cancer includes hepatocellular carcinoma.", icd10_code: "C22" }
]

liver_diseases.each do |disease|
  PredefinedDisease.find_or_create_by(name: disease[:name]) do |pd|
    pd.description = disease[:description]
    pd.icd10_code = disease[:icd10_code]
  end
end
Rails.logger.debug "Created liver diseases"

# Create user's liver diseases
hepatitis_b = PredefinedDisease.find_by(name: "hepatitis_b")
if hepatitis_b
  Disease.find_or_create_by(account: current_account, predefined_disease: hepatitis_b) do |d|
    d.name = "Hepatitis B"
    d.description = "Chronic hepatitis B infection"
    d.severity = "moderate"
    d.status = "active"
    d.diagnosed_date = 2.years.ago
    d.color = "#e74c3c"
  end
end

nafld = PredefinedDisease.find_by(name: "nafld")
if nafld
  Disease.find_or_create_by(account: current_account, predefined_disease: nafld) do |d|
    d.name = "NAFLD"
    d.description = "Non-alcoholic fatty liver disease"
    d.severity = "mild"
    d.status = "active"
    d.diagnosed_date = 1.year.ago
    d.color = "#f39c12"
  end
end
Rails.logger.debug "Created user's diseases"

# Create liver disease symptoms
liver_symptoms_data = {
  "hepatitis_b" => ["Fatigue", "Jaundice", "Abdominal pain", "Nausea", "Loss of appetite", "Dark urine"],
  "hepatitis_c" => ["Fatigue", "Jaundice", "Abdominal pain", "Nausea", "Joint pain"],
  "cirrhosis" => ["Fatigue", "Jaundice", "Swelling in legs", "Weight loss", "Confusion"],
  "nafld" => ["Fatigue", "Abdominal discomfort", "Weight loss", "Enlarged liver"]
}

liver_symptoms_data.each do |disease_name, symptoms|
  disease = PredefinedDisease.find_by(name: disease_name)
  next unless disease

  symptoms.each do |symptom_name|
    PredefinedSymptom.find_or_create_by(name: symptom_name, predefined_disease_id: disease.id) do |ps|
      ps.description = "Symptom associated with #{disease_name}"
    end
  end
end
Rails.logger.debug "Created liver disease symptoms"

# Create chatrooms with friends
friend = Account.where.not(id: current_account.id).first
if friend
  chatroom = Chatroom.create!(account1: current_account, account2: friend)

  messages = [
    "Hi! How are you doing?",
    "I've been better. Just got diagnosed with hepatitis B.",
    "I'm so sorry to hear that. Are you getting treatment?",
    "Yes, I have a great hepatologist. Dr. Smith is amazing!",
    "That's good to hear. Let me know if you need anything.",
    "Thanks! I appreciate your support."
  ]

  messages.each_with_index do |content, i|
    sender = i.even? ? current_account : friend
    ChatroomMessage.create!(account: sender, chatroom: chatroom, body: content, message_type: 0)
  end
  Rails.logger.debug "Created chatroom with messages"
end

# Create AI conversations
ai_conv = AiAgentConversation.create!(
  account: current_account,
  title: "Liver Health Assistant"
)

ai_messages = [
  { role: "user", content: "What are the early symptoms of hepatitis B?" },
  { role: "assistant", content: "Early symptoms of hepatitis B may include fatigue, loss of appetite, nausea, abdominal pain, and jaundice. However, many people with chronic hepatitis B may not experience any symptoms for years." },
  { role: "user", content: "How is NAFLD diagnosed?" },
  { role: "assistant", content: "NAFLD is typically diagnosed through blood tests showing elevated liver enzymes, imaging tests like ultrasound or MRI to detect fat in the liver, and sometimes a liver biopsy." },
  { role: "user", content: "What foods should I avoid with liver disease?" },
  { role: "assistant", content: "If you have liver disease, you should avoid: alcohol, fatty foods, salty foods, processed foods, and foods high in sugar. Focus on vegetables, fruits, lean proteins, and whole grains." }
]

ai_messages.each do |msg|
  AiAgentMessage.create!(conversation: ai_conv, role: msg[:role], content: msg[:content])
end
Rails.logger.debug "Created AI conversation"

# Create specialist recommendations
specialist = Specialist.first
if specialist
  SpecialistPatient.find_or_create_by(specialist: specialist, account: current_account) do |sp|
    sp.status = "active"
    sp.relationship_type = "consulting"
    sp.notes = "Patient with chronic hepatitis B"
  end

  SpecialistRecommendation.create!(
    specialist: specialist,
    account: current_account,
    recommendation_type: "medication",
    name: "Entecavir",
    dosage: "0.5mg once daily",
    status: "pending",
    notes: "Take on empty stomach"
  )

  SpecialistRecommendation.create!(
    specialist: specialist,
    account: current_account,
    recommendation_type: "lifestyle",
    name: "Diet Modification",
    dosage: "N/A",
    status: "pending",
    notes: "Low fat diet, avoid alcohol"
  )

  SpecialistNote.create!(
    specialist: specialist,
    account: current_account,
    content: "Patient is responding well to treatment. Continue current medication.",
    note_type: "observation"
  )
  Rails.logger.debug "Created specialist data"
end

# Create support groups
liver_group = Group.find_or_create_by(predefined_disease: hepatitis_b) do |g|
  g.name = "Hepatitis B Support Group"
  g.description = "A support group for people living with Hepatitis B"
end

GroupMember.find_or_create_by(group: liver_group, account: current_account) do |gm|
  gm.role = "member"
end
Rails.logger.debug "Created support groups"

# Create treatment
treatment = Treatment.find_or_create_by(account: current_account, name: "Hepatitis B Management") do |t|
  t.description = "Comprehensive treatment plan for Hepatitis B"
  t.status = "active"
  t.start_date = 6.months.ago
end

TreatmentDisease.find_or_create_by(treatment: treatment, disease: hepatitis_b) if hepatitis_b && treatment
Rails.logger.debug "Created treatment"

Rails.logger.debug "\n=== Data Summary ==="
Rails.logger.debug { "Diseases: #{Disease.count}" }
Rails.logger.debug { "Chatrooms: #{Chatroom.count}" }
Rails.logger.debug { "Chatroom Messages: #{ChatroomMessage.count}" }
Rails.logger.debug { "AI Messages: #{AiAgentMessage.count}" }
Rails.logger.debug { "Specialist Patients: #{SpecialistPatient.count}" }
Rails.logger.debug { "Groups: #{Group.count}" }
Rails.logger.debug { "Treatments: #{Treatment.count}" }
Rails.logger.debug "========================="
