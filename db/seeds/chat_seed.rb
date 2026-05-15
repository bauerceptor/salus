Rails.logger.debug "Seeding chat messages for chat functionality..."

# Get test accounts
patient = Account.joins(:user).where(users: { email: "patient@salus.com" }).first
doctor = Account.joins(:user).where(users: { email: "doctor@salus.com" }).first
all_accounts = Account.limit(20).to_a

accounts_to_chat = [patient, doctor, all_accounts].flatten.compact.uniq

Rails.logger.debug "Seeding chatrooms and messages..."

# Create chatrooms between accounts and add messages
accounts_to_chat.each do |account1|
  accounts_to_chat.each do |account2|
    next if account1.id >= account2.id # Avoid duplicates

    # Find or create chatroom
    min_id = [account1.id, account2.id].min
    max_id = [account1.id, account2.id].max
    chatroom = Chatroom.find_or_create_by(account1_id: min_id, account2_id: max_id)

    # Add 3-10 messages to each chatroom
    message_count = rand(3..10)
    message_count.times do |i|
      sender = [account1, account2].sample
      ChatroomMessage.create!(
        chatroom: chatroom,
        account: sender,
        body: "Message #{i + 1}: #{['Hello!', 'How are you?', 'Lets discuss your health.', 'Did you take your medication today?', 'Feeling better now?', 'Thanks for checking in!'].sample}",
        message_type: :text
      )
    end
  end
end

Rails.logger.debug { "Created #{Chatroom.count} chatrooms" }
Rails.logger.debug { "Created #{ChatroomMessage.count} chat messages" }

# Create some unread messages for the patient
if patient
  unread_count = 0
  Chatroom.where("account1_id = ? OR account2_id = ?", patient.id, patient.id).find_each do |chatroom|
    # Mark last message as unread for patient
    last_message = chatroom.chatroom_messages.last
    next unless last_message && last_message.account_id != patient.id

    # Create a ChatroomParticipant with unread status
    ChatroomParticipant.find_or_create_by(chatroom: chatroom, account: patient) do |cp|
      cp.last_read_at = 1.hour.ago
    end
    unread_count += 1
  end
  Rails.logger.debug { "Unread conversations for patient: #{unread_count}" }
end

Rails.logger.debug "\nChat seeding complete!"
