Rails.logger.debug "Creating comprehensive dummy data..."

# Get current account
current_account = Account.first
current_user = current_account.user

Rails.logger.debug { "Current user: #{current_user.email}" }

# Create liver-related predefined diseases if they don't exist
liver_diseases = [
  { name: "hepatitis_b", description: "Hepatitis B is a liver infection caused by the hepatitis B virus (HBV).", icd10_code: "B16" },
  { name: "hepatitis_c", description: "Hepatitis C is a liver infection caused by the hepatitis C virus (HCV).", icd10_code: "B17" },
  { name: "cirrhosis", description: "Cirrhosis is a late stage of progressive liver fibrosis characterized by distortion of the liver architecture.", icd10_code: "K74" },
  { name: "nafld", description: "Non-alcoholic fatty liver disease (NAFLD) is a condition where fat builds up in the liver.", icd10_code: "K76" },
  { name: "nash", description: "Non-alcoholic steatohepatitis (NASH) is an advanced form of NAFLD characterized by liver inflammation.", icd10_code: "K75" },
  { name: "liver_cancer", description: "Liver cancer includes hepatocellular carcinoma and cholangiocarcinoma.", icd10_code: "C22" }
]

liver_diseases.each do |disease|
  PredefinedDisease.find_or_create_by(name: disease[:name]) do |pd|
    pd.description = disease[:description]
    pd.icd10_code = disease[:icd10_code]
  end
end
Rails.logger.debug "Created liver diseases"

# Create liver disease symptoms for each liver disease
liver_symptoms_data = {
  "hepatitis_b" => ["Fatigue", "Jaundice", "Abdominal pain", "Nausea", "Loss of appetite", "Dark urine"],
  "hepatitis_c" => ["Fatigue", "Jaundice", "Abdominal pain", "Nausea", "Joint pain"],
  "cirrhosis" => ["Fatigue", "Jaundice", "Swelling in legs", "Weight loss", "Confusion", "Spider angiomas"],
  "nafld" => ["Fatigue", "Abdominal discomfort", "Weight loss", "Enlarged liver"],
  "nash" => ["Fatigue", "Severe abdominal pain", "Yellowing of skin", "Swelling"],
  "liver_cancer" => ["Unexplained weight loss", "Loss of appetite", "Upper abdominal pain", "Jaundice", "White stool"]
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

# Create user's liver disease
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

# Create additional users with accounts (friends and doctors)
users_data = [
  { email: "sarah.johnson@example.com", first_name: "Sarah", last_name: "Johnson", doctor: false },
  { email: "dr.micheal@example.com", first_name: "Michael", last_name: "Smith", doctor: true, specialty: "Hepatologist" },
  { email: "emily.davis@example.com", first_name: "Emily", last_name: "Davis", doctor: false },
  { email: "dr.james@example.com", first_name: "James", last_name: "Wilson", doctor: true, specialty: "Gastroenterologist" },
  { email: "robert.brown@example.com", first_name: "Robert", last_name: "Brown", doctor: false },
  { email: "lisa.white@example.com", first_name: "Lisa", last_name: "White", doctor: false },
  { email: "david.lee@example.com", first_name: "David", last_name: "Lee", doctor: true, specialty: "Hepatologist" }
]

accounts_created = []
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

  account = Account.create!(
    user_id: user.id,
    email: user.email,
    first_name: user.first_name,
    last_name: user.last_name,
    username: user.email.split("@").first,
    city: "New York",
    country: "USA",
    education: "bachelor"
  )
  accounts_created << account

  if user_data[:doctor]
    Specialist.find_or_create_by(user: user) do |s|
      s.field_of_expertise = user_data[:specialty]
      s.license_number = "MD-#{rand(10_000..99_999)}"
      s.status = "active"
    end
    Rails.logger.debug { "Created specialist: #{user.email}" }
  else
    Rails.logger.debug { "Created user: #{user.email}" }
  end
end

all_accounts = Account.all.to_a
doctor_accounts, friend_accounts = all_accounts.partition { |a| a.user&.specialist? }

# Create friendships
friend_accounts.each do |friend|
  next if friend.id == current_account.id
  next if Friendship.exists?(account: current_account, friend: friend)

  Friendship.create!(account: current_account, friend: friend, status: "accepted")
  Friendship.create!(account: friend, friend: current_account, status: "accepted")
end
Rails.logger.debug "Created friendships"

# Create conversations (for chat)
conversation = Conversation.create!
ConversationParticipant.create!(account: current_account, conversation: conversation)
friend = friend_accounts.find { |f| f.id != current_account.id }
ConversationParticipant.create!(account: friend, conversation: conversation) if friend

# Create messages in conversation
messages_content = [
  "Hi, how are you feeling today?",
  "I have been feeling tired lately, not sure why.",
  "Have you been taking your medication regularly?",
  "Yes, I have been following the doctor's advice.",
  "That's great! Keep it up.",
  "Thanks for checking in on me!"
]

messages_content.each_with_index do |content, i|
  sender = i.even? ? current_account : friend
  Message.create!(
    account: sender,
    conversation: conversation,
    body: content,
    message_type: "text"
  )
end
Rails.logger.debug "Created conversation with messages"

# Create AI agent conversations
ai_conversation = AiAgentConversation.create!(
  account: current_account,
  title: "Liver Health Questions"
)

ai_messages = [
  { role: "user", content: "What are the early symptoms of hepatitis B?" },
  { role: "assistant", content: "Early symptoms of hepatitis B may include fatigue, loss of appetite, nausea, abdominal pain, and jaundice. However, many people with chronic hepatitis B may not experience any symptoms for years." },
  { role: "user", content: "How is NAFLD diagnosed?" },
  { role: "assistant", content: "NAFLD is typically diagnosed through blood tests showing elevated liver enzymes, imaging tests like ultrasound or MRI to detect fat in the liver, and sometimes a liver biopsy to determine the extent of liver damage." },
  { role: "user", content: "What foods should I avoid with liver disease?" },
  { role: "assistant", content: "If you have liver disease, you should avoid: alcohol, fatty foods, salty foods, processed foods, and foods high in sugar. Focus on a balanced diet with vegetables, fruits, lean proteins, and whole grains." }
]

ai_messages.each do |msg|
  AiAgentMessage.create!(
    conversation: ai_conversation,
    role: msg[:role],
    content: msg[:content]
  )
end
Rails.logger.debug "Created AI agent conversation"

# Create specialist patients (relationship with doctors)
doctor_accounts.each do |doctor|
  specialist = doctor.user.specialist
  next unless specialist

  SpecialistPatient.find_or_create_by(specialist: specialist, account: current_account) do |sp|
    sp.status = "active"
    sp.relationship_type = "consulting"
    sp.notes = "Patient with chronic hepatitis B and NAFLD"
  end
end
Rails.logger.debug "Created specialist patient relationships"

# Create specialist recommendations
if doctor_accounts.any?
  doctor = doctor_accounts.first
  specialist = doctor.user.specialist

  SpecialistRecommendation.create!(
    specialist: specialist,
    account: current_account,
    recommendation_type: "medication",
    name: "Entecavir",
    dosage: "0.5mg once daily",
    status: "pending",
    notes: "Take on empty stomach for best absorption"
  )

  SpecialistRecommendation.create!(
    specialist: specialist,
    account: current_account,
    recommendation_type: "lifestyle",
    name: "Diet Modification",
    dosage: "N/A",
    status: "pending",
    notes: "Low fat diet, avoid alcohol completely"
  )

  SpecialistNote.create!(
    specialist: specialist,
    account: current_account,
    content: "Patient showing good response to current treatment. Continue with regular monitoring every 6 months.",
    note_type: "observation"
  )
end
Rails.logger.debug "Created specialist recommendations and notes"

# Create medications for liver disease
Medication.find_or_create_by(account: current_account, name: "Entecavir") do |m|
  m.dosage = "0.5mg"
  m.frequency = "Once daily"
  m.instructions = "Take on empty stomach"
  m.is_active = true
  m.start_date = 6.months.ago
end

Medication.find_or_create_by(account: current_account, name: "Ursodeoxycholic Acid") do |m|
  m.dosage = "250mg"
  m.frequency = "Twice daily"
  m.instructions = "Take with food"
  m.is_active = true
  m.start_date = 3.months.ago
end
Rails.logger.debug "Created medications"

# Create measurements for liver function
MeasurementType.find_or_create_by(name: "liver_enzyme") do |mt|
  mt.unit = "U/L"
  mt.lower_limit = "10"
  mt.upper_limit = "40"
end

# Create notes related to liver health
Note.find_or_create_by(account: current_account, title: "Liver Function Test Results") do |n|
  n.content = "ALT: 35 U/L, AST: 28 U/L - Both within normal range. Good progress!"
  n.note_type = "medical"
  n.is_pinned = true
  n.background_color = "#27ae60"
end

Note.find_or_create_by(account: current_account, title: "Doctor Appointment - Hepatologist") do |n|
  n.content = "Scheduled for March 15th at 10:00 AM with Dr. Michael Smith. Bring all recent test results."
  n.note_type = "appointment"
  n.is_pinned = false
  n.background_color = "#3498db"
end

Note.find_or_create_by(account: current_account, title: "Diet Tips for Liver Health") do |n|
  n.content = "Eat: Leafy greens, carrots, avocados, lean proteins. Avoid: Alcohol, fatty foods, excessive sugar, processed meats."
  n.note_type = "general"
  n.is_pinned = false
  n.background_color = ""
end

Note.find_or_create_by(account: current_account, title: "Medication Schedule Reminder") do |n|
  n.content = "Morning: Entecavir on empty stomach. Evening: Ursodeoxycholic Acid with dinner."
  n.note_type = "reminder"
  n.is_pinned = true
  n.background_color = "#9b59b6"
end
Rails.logger.debug "Created notes"

# Create groups for liver disease support
liver_group = Group.find_or_create_by(predefined_disease: hepatitis_b) do |g|
  g.name = "Hepatitis B Support Group"
  g.description = "A support group for people living with Hepatitis B"
end

GroupMember.find_or_create_by(group: liver_group, account: current_account) do |gm|
  gm.role = "member"
end

if friend_accounts.any?
  GroupMember.find_or_create_by(group: liver_group, account: friend_accounts.first) do |gm|
    gm.role = "member"
  end
end
Rails.logger.debug "Created support groups"

# Create notifications
Notification.create!(
  account: current_account,
  title: "Time for your medication",
  body: "It's time to take your Entecavir medication.",
  notification_type: "medication_reminder"
)

Notification.create!(
  account: current_account,
  title: "New message from Dr. Smith",
  body: "Your hepatologist has sent you a new message regarding your test results.",
  notification_type: "message"
)

Notification.create!(
  account: current_account,
  title: "Upcoming appointment",
  body: "You have an appointment scheduled for March 15th with Dr. Michael Smith.",
  notification_type: "appointment_reminder"
)

Notification.create!(
  account: current_account,
  title: "Lab results ready",
  body: "Your recent liver function test results are now available.",
  notification_type: "general"
)
Rails.logger.debug "Created notifications"

# Create treatment
treatment = Treatment.find_or_create_by(account: current_account, name: "Hepatitis B Management") do |t|
  t.description = "Comprehensive treatment plan for chronic Hepatitis B"
  t.status = "active"
  t.start_date = 6.months.ago
end

TreatmentDisease.find_or_create_by(treatment: treatment, disease: hepatitis_b) if hepatitis_b
Rails.logger.debug "Created treatment"

Rails.logger.debug { "\n#{'=' * 50}" }
Rails.logger.debug "DUMMY DATA CREATION COMPLETE"
Rails.logger.debug "=" * 50
Rails.logger.debug { "Users: #{User.count}" }
Rails.logger.debug { "Accounts: #{Account.count}" }
Rails.logger.debug { "Diseases: #{Disease.count}" }
Rails.logger.debug { "Medications: #{Medication.count}" }
Rails.logger.debug { "Notes: #{Note.count}" }
Rails.logger.debug { "Notifications: #{Notification.count}" }
Rails.logger.debug { "Measurements: #{Measurement.count}" }
Rails.logger.debug { "Friendships: #{Friendship.count}" }
Rails.logger.debug { "Conversations: #{Conversation.count}" }
Rails.logger.debug { "Messages: #{Message.count}" }
Rails.logger.debug { "AI Conversations: #{AiAgentConversation.count}" }
Rails.logger.debug { "AI Messages: #{AiAgentMessage.count}" }
Rails.logger.debug { "Specialists: #{Specialist.count}" }
Rails.logger.debug { "Specialist Patients: #{SpecialistPatient.count}" }
Rails.logger.debug { "Specialist Recommendations: #{SpecialistRecommendation.count}" }
Rails.logger.debug { "Groups: #{Group.count}" }
Rails.logger.debug { "Group Members: #{GroupMember.count}" }
Rails.logger.debug "=" * 50
