module Notifications
  class Generator
    class << self
      def generate_for_account(account)
        return if notification_already_generated_recently?(account)

        generators = [
          method(:generate_appointment_reminders),
          method(:generate_medication_reminders),
          method(:generate_measurement_reminders),
          method(:generate_group_activity),
          method(:generate_doctor_notes),
          method(:generate_friend_activity),
          method(:generate_health_tips)
        ]

        # Run 1-3 random generators
        generators.shuffle.take(rand(1..3)).each do |generator|
          generator.call(account)
        end
      end

      def generate_appointment_reminders(account)
        return if account.diseases.empty?

        appointment_notifications = [
          "You have an appointment tomorrow at #{rand(8..16)}:00 with your hepatologist.",
          "Reminder: Follow-up visit scheduled for next week.",
          "Your appointment has been confirmed for #{2.weeks.from_now.strftime('%B %d')}."
        ]

        create_notification(
          account: account,
          title: "Upcoming Appointment",
          body: appointment_notifications.sample,
          notification_type: "appointment_reminder"
        )
      end

      def generate_medication_reminders(account)
        medications = account.medications.active
        return if medications.empty?

        med = medications.sample
        reminder_messages = [
          "Time to take your #{med.name} - #{med.dosage}.",
          "Don't forget your #{med.name} medication!",
          "Medication reminder: #{med.name} (#{med.dosage}) is due now."
        ]

        create_notification(
          account: account,
          title: "Medication Reminder",
          body: reminder_messages.sample,
          notification_type: "medication_reminder"
        )
      end

      def generate_measurement_reminders(account)
        measurement_notifications = [
          "It's been a while since your last weight measurement.",
          "Consider logging your blood pressure today.",
          "Time for your weekly health check-up. Log your measurements to track progress."
        ]

        create_notification(
          account: account,
          title: "Measurement Reminder",
          body: measurement_notifications.sample,
          notification_type: "measurement_reminder"
        )
      end

      def generate_group_activity(account)
        groups = account.groups
        return if groups.empty?

        group = groups.sample
        activities = [
          "#{group.name} has a new post from a member.",
          "Someone commented in #{group.name}.",
          "New discussion started in #{group.name}. Join the conversation!",
          "A new member joined #{group.name}."
        ]

        create_notification(
          account: account,
          title: "Group Activity",
          body: activities.sample,
          notification_type: "group_activity"
        )
      end

      def generate_doctor_notes(account)
        doctors = ["Dr. Smith", "Dr. Johnson", "Dr. Williams", "Dr. Brown"]
        notes = [
          "#{doctors.sample} added a note to your health record.",
          "Your specialist has uploaded new lab results for review.",
          "A care team member shared new recommendations for your treatment."
        ]

        create_notification(
          account: account,
          title: "Doctor's Note",
          body: notes.sample,
          notification_type: "doctor_note"
        )
      end

      def generate_friend_activity(account)
        return if account.friends.empty?

        friend = account.friends.sample
        activities = [
          "#{friend.full_name} shared a new health update.",
          "#{friend.full_name} posted in your support group.",
          "#{friend.full_name} commented on your recent post."
        ]

        create_notification(
          account: account,
          title: "Friend Activity",
          body: activities.sample,
          notification_type: "general"
        )
      end

      def generate_health_tips(account)
        tips = [
          "Did you know? Drinking coffee may help protect your liver.",
          "Tip: Regular exercise can help reduce liver fat.",
          "Remember: Limit alcohol intake to protect your liver health.",
          "Health tip: Foods rich in antioxidants support liver function.",
          "Tip: Stay hydrated! Water helps your liver function properly."
        ]

        create_notification(
          account: account,
          title: "Health Tip",
          body: tips.sample,
          notification_type: "general"
        )
      end

      private

      def notification_already_generated_recently?(account)
        recent_cutoff = 1.hour.ago
        account.notifications.exists?(["created_at > ?", recent_cutoff])
      end

      def create_notification(account:, title:, body:, notification_type:)
        Notification.create!(
          account: account,
          title: title,
          body: body,
          notification_type: notification_type
        )
      end
    end
  end
end
