Rails.logger.debug "Seeding john.doe user data..."

john = User.find_or_create_by!(email: "john.doe@example.com") do |u|
  u.password = "password"
  u.password_confirmation = "password"
  u.tos_agreement = true
end

unless john.account
  account = john.build_account(
    first_name: "John",
    last_name: "Doe",
    username: "john.doe"
  )
  account.save!
end

account = john.account

hepatitis_b = PredefinedDisease.find_or_create_by(name: "hepatitis_b") do |pd|
  pd.description = "Hepatitis B is a liver infection caused by the hepatitis B virus (HBV)."
  pd.icd10_code = "B16"
end

nafld = PredefinedDisease.find_or_create_by(name: "nafld") do |pd|
  pd.description = "Non-alcoholic fatty liver disease (NAFLD) is a condition where fat builds up in the liver."
  pd.icd10_code = "K76"
end

cirrhosis = PredefinedDisease.find_or_create_by(name: "cirrhosis") do |pd|
  pd.description = "Cirrhosis is a late stage of progressive liver fibrosis characterized by distortion of the liver architecture."
  pd.icd10_code = "K74"
end

Disease.find_or_create_by!(account: account, predefined_disease: hepatitis_b) do |d|
  d.name = "Hepatitis B"
  d.severity = 3
  d.color = "#e74c3c"
  d.status = "active"
  d.diagnosed_at = 2.years.ago
end

Disease.find_or_create_by!(account: account, predefined_disease: nafld) do |d|
  d.name = "NAFLD"
  d.severity = 2
  d.color = "#f39c12"
  d.status = "active"
  d.diagnosed_at = 1.year.ago
end

Disease.find_or_create_by!(account: account, predefined_disease: cirrhosis) do |d|
  d.name = "Cirrhosis"
  d.severity = 4
  d.color = "#e67e22"
  d.status = "active"
  d.diagnosed_at = 6.months.ago
end

hepatitis_b_group = Group.find_or_create_by(predefined_disease: hepatitis_b) do |g|
  g.name = "Hepatitis B Support Group"
  g.description = "A support group for people living with Hepatitis B"
end

nafld_group = Group.find_or_create_by(predefined_disease: nafld) do |g|
  g.name = "NAFLD Support Group"
  g.description = "A support group for people living with Non-alcoholic Fatty Liver Disease"
end

cirrhosis_group = Group.find_or_create_by(predefined_disease: cirrhosis) do |g|
  g.name = "Cirrhosis Support Group"
  g.description = "A support group for people living with Cirrhosis"
end

GroupMember.find_or_create_by(group: hepatitis_b_group, account: account)
GroupMember.find_or_create_by(group: nafld_group, account: account)
GroupMember.find_or_create_by(group: cirrhosis_group, account: account)

Note.find_or_create_by(account: account, title: "Liver Function Test Results") do |n|
  n.content = "ALT: 35 U/L, AST: 28 U/L - Both within normal range. Good progress!"
  n.note_type = "medical"
  n.is_pinned = true
  n.background_color = "#27ae60"
end

Note.find_or_create_by(account: account, title: "Doctor Appointment - Hepatologist") do |n|
  n.content = "Scheduled for March 15th at 10:00 AM with Dr. Michael Smith. Bring all recent test results."
  n.note_type = "appointment"
  n.is_pinned = false
  n.background_color = "#3498db"
end

Note.find_or_create_by(account: account, title: "Diet Tips for Liver Health") do |n|
  n.content = "Eat: Leafy greens, carrots, avocados, lean proteins. Avoid: Alcohol, fatty foods, excessive sugar, processed meats."
  n.note_type = "general"
  n.is_pinned = false
end

Note.find_or_create_by(account: account, title: "Medication Schedule Reminder") do |n|
  n.content = "Morning: Entecavir on empty stomach. Evening: Ursodeoxycholic Acid with dinner."
  n.note_type = "reminder"
  n.is_pinned = true
  n.background_color = "#9b59b6"
end

ai_conversation = AiAgentConversation.find_or_create_by(account: account, title: "Liver Health Questions") do |c|
end

ai_messages = [
  { role: "user", content: "What are the early symptoms of hepatitis B?" },
  { role: "assistant", content: "Early symptoms of hepatitis B may include fatigue, loss of appetite, nausea, abdominal pain, and jaundice. However, many people with chronic hepatitis B may not experience any symptoms for years." },
  { role: "user", content: "How is NAFLD diagnosed?" },
  { role: "assistant", content: "NAFLD is typically diagnosed through blood tests showing elevated liver enzymes, imaging tests like ultrasound or MRI to detect fat in the liver, and sometimes a liver biopsy to determine the extent of liver damage." },
  { role: "user", content: "What foods should I avoid with liver disease?" },
  { role: "assistant", content: "If you have liver disease, you should avoid: alcohol, fatty foods, salty foods, processed foods, and foods high in sugar. Focus on a balanced diet with vegetables, fruits, lean proteins, and whole grains." }
]

ai_messages.each do |msg|
  AiAgentMessage.find_or_create_by(conversation: ai_conversation, role: msg[:role], content: msg[:content])
end

friend_account = Account.where.not(id: account.id).first
if friend_account
  chatroom = Chatroom.find_or_create_by(account1: account, account2: friend_account)

  messages_content = [
    "Hi, how are you feeling today?",
    "I have been feeling tired lately, not sure why.",
    "Have you been taking your medication regularly?",
    "Yes, I have been following the doctor's advice.",
    "That's great! Keep it up.",
    "Thanks for checking in on me!"
  ]

  messages_content.each_with_index do |content, i|
    sender = i.even? ? account : friend_account
    ChatroomMessage.find_or_create_by(chatroom: chatroom, account: sender, body: content)
  end
end

Rails.logger.debug "John Doe data seeding complete!"
