Rails.logger.debug "Adding dashboard UI data..."

account_ids = ActiveRecord::Base.connection.select_all(
  "SELECT id FROM accounts LIMIT 20"
).pluck("id")

accounts = Account.where(id: account_ids)
specialists = User.joins(:roles).where(roles: { name: "specialist" }).limit(5).to_a

Rails.logger.debug "Seeding DiseaseStatus posts with reactions and comments..."
accounts.each do |account|
  next unless account.diseases.any?

  disease = account.diseases.first
  5.times do |i|
    status = DiseaseStatus.create!(
      disease: disease,
      status: %w[diagnosed improvement deterioration].sample,
      content: "Health update #{i + 1}: Feeling #{['better', 'the same', 'worse'].sample} today",
      mood: [1, 2, 3].sample
    )

    rand(0..5).times do
      Reaction.find_or_create_by(
        reactable: status,
        account: accounts.sample
      ) do |r|
        r.reaction_type = %w[heart thumbs_up sad].sample
      end
    end

    rand(0..3).times do
      Comment.find_or_create_by(
        commentable: status,
        account: accounts.sample
      ) do |c|
        c.body = "Thanks for sharing! Hope you feel better soon."
      end
    end
  end
end
Rails.logger.debug { "  Created #{DiseaseStatus.count} disease statuses" }

Rails.logger.debug "Seeding MedicationSchedules and MedicationLogs..."
accounts.each do |account|
  account.medications.active.each do |med|
    times = [
      { hour: 8, minute: 0, period: "morning" },
      { hour: 12, minute: 0, period: "afternoon" },
      { hour: 18, minute: 0, period: "evening" },
      { hour: 22, minute: 0, period: "night" }
    ]

    times.sample(rand(1..4)).each do |t|
      schedule = MedicationSchedule.find_or_create_by(
        medication: med,
        day_of_week: Time.zone.today.wday
      ) do |ms|
        ms.scheduled_time = Time.zone.local(2026, 4, 25, t[:hour], t[:minute])
        ms.is_active = true
      end

      MedicationLog.find_or_create_by(
        medication_schedule: schedule,
        account: account,
        medication: med
      ) do |ml|
        ml.status = %w[taken pending missed].sample
        ml.scheduled_for = Time.zone.local(2026, 4, 25, t[:hour], t[:minute])
        ml.taken_at = ml.status == "taken" ? Time.current : nil
      end
    end
  end
end
Rails.logger.debug { "  Created #{MedicationSchedule.count} medication schedules" }
Rails.logger.debug { "  Created #{MedicationLog.count} medication logs" }

Rails.logger.debug "Seeding SpecialistNotifications (alerts)..."
specialists.each do |specialist|
  next unless specialist.id

  specialist_patients = SpecialistPatient.where(specialist_id: specialist.id).limit(5)
  specialist_patients.each do |sp|
    notification_types = [
      { type: "sos_alert", title: "Emergency Alert", message: "Patient #{sp.account.full_name} triggered emergency alert" },
      { type: "missed_medication", title: "Missed Medication", message: "Patient missed their morning medication" },
      { type: "low_adherence", title: "Low Adherence", message: "Patient adherence rate dropped below 70%" },
      { type: "abnormal_measurement", title: "Abnormal Reading", message: "Blood pressure reading outside normal range" },
      { type: "new_message", title: "New Message", message: "Patient sent a new message" },
      { type: "recommendation_response", title: "Recommendation Response", message: "Patient responded to your recommendation" }
    ]

    notification_types.sample(rand(2..5)).each do |n|
      SpecialistNotification.find_or_create_by(
        specialist_id: specialist.id,
        patient_id: sp.account.id,
        notification_type: n[:type]
      ) do |sn|
        sn.title = n[:title]
        sn.message = n[:message]
        sn.is_read = [true, false].sample
      end
    end
  end
end
Rails.logger.debug { "  Created #{SpecialistNotification.count} specialist notifications" }

Rails.logger.debug "Seeding TreatmentRequests..."
accounts.each do |account|
  next if account.treatment_requests.count >= 2

  2.times do |i|
    TreatmentRequest.find_or_create_by(
      account: account,
      title: "Treatment Request #{i + 1}"
    ) do |tr|
      tr.description = "Request for treatment plan regarding #{account.diseases.first&.name || 'health condition'}"
      tr.status = %w[pending approved rejected].sample
      tr.start_date = rand(1..3).months.from_now
    end
  end
end
Rails.logger.debug { "  Created #{TreatmentRequest.count} treatment requests" }

Rails.logger.debug "Seeding Groups and GroupPosts..."
sample_accounts = accounts.first(10)
predefined_diseases = PredefinedDisease.first(5)

group_names = [
  "Diabetes Support Group",
  "Heart Health Community",
  "Fitness & Wellness",
  "Mental Health Support",
  "Chronic Pain Management"
]

groups = group_names.each_with_index.map do |name, idx|
  pd = predefined_diseases[idx % predefined_diseases.count]
  Group.find_or_create_by(name: name, predefined_disease: pd) do |g|
    g.description = "Support group for #{name.downcase}"
  end
end

groups.each do |group|
  sample_accounts.sample(rand(3..7)).each do |account|
    GroupMember.find_or_create_by(group: group, account: account) do |gm|
      gm.role = %w[member moderator].sample
    end
  end
end
Rails.logger.debug { "  Created #{Group.count} groups" }
Rails.logger.debug { "  Created #{GroupPost.count} group posts" }
Rails.logger.debug { "  Created #{GroupMember.count} group members" }

Rails.logger.debug "Seeding Caregivers..."
accounts.first(5).each do |account|
  Caregiver.find_or_create_by(caregiver_account: account, account: accounts.sample) do |c|
    c.relationship = "family"
    c.is_accepted = true
    c.can_view_diseases = true
    c.can_view_medications = true
    c.can_view_measurements = true
    c.notify_on_abnormal_measurement = true
    c.notify_on_missed_dose = true
  end
end
Rails.logger.debug { "  Created #{Caregiver.count} caregivers" }

Rails.logger.debug "Seeding SpecialistMessages..."
specialists.each do |specialist|
  SpecialistPatient.where(specialist_id: specialist.id).limit(3).each do |sp|
    3.times do |i|
      SpecialistMessage.find_or_create_by(
        specialist: specialist,
        account: sp.account,
        subject: "Message #{i + 1}"
      ) do |sm|
        sm.body = "This is a message from your specialist regarding your care plan."
        sm.is_read = i.even?
      end
    end
  end
end
Rails.logger.debug { "  Created #{SpecialistMessage.count} specialist messages" }

Rails.logger.debug "\n=== Dashboard UI Data Seeding Complete ==="
Rails.logger.debug { "Disease Statuses: #{DiseaseStatus.count}" }
Rails.logger.debug { "Reactions: #{Reaction.count}" }
Rails.logger.debug { "Comments: #{Comment.count}" }
Rails.logger.debug { "Medication Schedules: #{MedicationSchedule.count}" }
Rails.logger.debug { "Medication Logs: #{MedicationLog.count}" }
Rails.logger.debug { "Specialist Notifications: #{SpecialistNotification.count}" }
Rails.logger.debug { "Treatment Requests: #{TreatmentRequest.count}" }
Rails.logger.debug { "Groups: #{Group.count}" }
Rails.logger.debug { "Group Posts: #{GroupPost.count}" }
Rails.logger.debug { "Group Members: #{GroupMember.count}" }
Rails.logger.debug { "Caregivers: #{Caregiver.count}" }
Rails.logger.debug { "Specialist Messages: #{SpecialistMessage.count}" }
Rails.logger.debug { "Medication Requests: #{MedicationRequest.count}" }
Rails.logger.debug "=========================================="
