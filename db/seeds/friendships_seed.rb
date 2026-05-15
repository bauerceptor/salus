Rails.logger.debug "Creating friendships between accounts for chat functionality..."

# Get test accounts
patient = Account.joins(:user).where(users: { email: "patient@salus.com" }).first
doctor = Account.joins(:user).where(users: { email: "doctor@salus.com" }).first

# Get other accounts for cross-linking
all_accounts = Account.where.not(id: [patient&.id, doctor&.id]).limit(50).to_a
accounts_with_patient = [patient, doctor, all_accounts].flatten.compact.uniq

Rails.logger.debug { "Patient: #{patient&.full_name || 'Not found'}" }
Rails.logger.debug { "Doctor: #{doctor&.full_name || 'Not found'}" }
Rails.logger.debug { "Total accounts for friending: #{accounts_with_patient.count}" }

# Create friendships between patient and several other accounts
if patient
  friends_to_add = all_accounts.first(15)
  Rails.logger.debug { "\nAdding #{friends_to_add.count} friends to patient..." }

  friends_to_add.each do |friend|
    next if friend.id == patient.id

    # Create bidirectional friendship
    unless Friendship.exists?(account: patient, friend: friend)
      Friendship.create!(account: patient, friend: friend, status: "accepted")
      Rails.logger.debug { "  Added friend: #{friend.full_name}" }
    end

    unless Friendship.exists?(account: friend, friend: patient)
      Friendship.create!(account: friend, friend: patient, status: "accepted")
    end
  end
end

# Create friendships between doctor and several accounts
if doctor
  friends_to_add = all_accounts.first(10)
  Rails.logger.debug { "\nAdding #{friends_to_add.count} friends to doctor..." }

  friends_to_add.each do |friend|
    next if friend.id == doctor.id

    unless Friendship.exists?(account: doctor, friend: friend)
      Friendship.create!(account: doctor, friend: friend, status: "accepted")
      Rails.logger.debug { "  Added friend: #{friend.full_name}" }
    end

    unless Friendship.exists?(account: friend, friend: doctor)
      Friendship.create!(account: friend, friend: doctor, status: "accepted")
    end
  end
end

# Create cross-friendships between all accounts (everyone is friends with everyone)
Rails.logger.debug "\nCreating cross-friendships between all accounts..."
accounts_with_patient.each do |account1|
  accounts_with_patient.each do |account2|
    next if account1.id == account2.id

    unless Friendship.exists?(account: account1, friend: account2)
      Friendship.create!(account: account1, friend: account2, status: "accepted")
    end
  end
end

Rails.logger.debug "\n=== Friendship Statistics ==="
Rails.logger.debug { "Total friendships: #{Friendship.count}" }
Rails.logger.debug { "Patient friends: #{patient&.friends&.count || 0}" }
Rails.logger.debug { "Doctor friends: #{doctor&.friends&.count || 0}" }

# Display some friendship examples
Rails.logger.debug "\nSample friendships:"
Friendship.first(10).each do |f|
  Rails.logger.debug "  #{f.account.full_name} <-> #{f.friend.full_name}"
end

Rails.logger.debug "\nFriendship seeding complete!"
