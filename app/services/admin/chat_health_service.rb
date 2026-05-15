class Admin::ChatHealthService
  def health_stats
    all_specialists.map do |specialist_user|
      build_stat_hash(specialist_user)
    end
  end

  private

  def all_specialists
    User.joins(:roles, :specialist)
        .where(roles: { name: "specialist" })
        .order(created_at: :asc)
  end

  def build_stat_hash(specialist_user)
    specialist_id = specialist_user.id

    {
      specialist_id: specialist_id,
      specialist_name: specialist_user.account&.full_name || specialist_user.email,
      specialization: specialist_user.specialist&.specialization || "N/A",
      messages_sent_last_30d: messages_count(specialist_id),
      zero_history_patients: zero_history_count(specialist_id),
      last_message_at: last_message_time(specialist_id)
    }
  end

  def messages_count(specialist_id)
    SpecialistMessage.where(specialist_id: specialist_id)
                     .where(created_at: 30.days.ago..)
                     .count
  end

  def zero_history_count(specialist_id)
    active_patient_ids = SpecialistPatient.active.where(specialist_id: specialist_id).pluck(:account_id)
    patient_ids_with_messages = SpecialistMessage.where(specialist_id: specialist_id).pluck(:account_id).uniq

    active_patient_ids.count - patient_ids_with_messages.count
  end

  def last_message_time(specialist_id)
    last_message = SpecialistMessage.where(specialist_id: specialist_id)
                                    .order(created_at: :desc)
                                    .first

    last_message&.created_at
  end
end
