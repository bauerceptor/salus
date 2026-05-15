class PatientCareHistoryService
  EVENT_CONFIG = {
    diagnosis: { icon: "ri-heart-pulse-line", severity: "red" },
    medication_start: { icon: "ri-medicine-bottle-line", severity: "yellow" },
    medication_end: { icon: "ri-checkbox-circle-line", severity: "red" },
    treatment_started: { icon: "ri-flight-takeoff-line", severity: "yellow" },
    treatment_ended: { icon: "ri-flag-line", severity: "red" },
    treatment_update: { icon: "ri-refresh-line", severity: "yellow" },
    note: { icon: "ri-sticky-note-line", severity: "blue" },
    recommendation_sent: { icon: "ri-send-plane-line", severity: "blue" },
    recommendation_accepted: { icon: "ri-check-double-line", severity: "green" },
    recommendation_rejected: { icon: "ri-close-circle-line", severity: "red" },
    medication_request: { icon: "ri-file-list-3-line", severity: "gray" },
    medication_request_resolved: { icon: "ri-check-line", severity: "green" },
    message: { icon: "ri-message-3-line", severity: "blue" },
    appointment: { icon: "ri-calendar-event-line", severity: "gray" },
    measurement: { icon: "ri-heart-line", severity: "red" }
  }.freeze

  def initialize(account, scope: :recent)
    @account = account
    @scope = scope
  end

  def events
    @events ||= build_events.sort_by { |e| e[:timestamp] }.reverse
  end

  private

  attr_reader :account

  def build_events
    events = []
    events.concat(diagnosis_events)
    events.concat(medication_events)
    events.concat(treatment_events)
    events.concat(note_events)
    events.concat(recommendation_events)
    events.concat(message_events)
    events.concat(appointment_events)
    events.concat(medication_request_events)
    events.concat(measurement_events)
    events
  end

  def date_from
    @scope == :full ? 100.years.ago : 30.days.ago
  end

  def diagnosis_events
    account.diseases
           .where(diagnosed_at: date_from..)
           .map do |disease|
             {
               type: :diagnosis,
               title: disease.predefined_disease&.name || disease.name || "Unknown Condition",
               description: "Diagnosed on #{disease.diagnosed_at.strftime('%b %d, %Y')}",
               timestamp: disease.diagnosed_at.to_time,
               icon: EVENT_CONFIG[:diagnosis][:icon],
               severity: EVENT_CONFIG[:diagnosis][:severity],
               metadata: { disease_id: disease.id }
             }
           end
  end

  def medication_events
    events = []
    account.medications.where(created_at: date_from..).find_each do |med|
      if med.start_date.present? && med.is_active?
        events << {
          type: :medication_start,
          title: med.name,
          description: [med.dosage, med.frequency].compact.join(" — "),
          timestamp: med.start_date.to_time,
          icon: EVENT_CONFIG[:medication_start][:icon],
          severity: EVENT_CONFIG[:medication_start][:severity],
          metadata: { medication_id: med.id }
        }
      end
      next if med.end_date.blank?

      events << {
        type: :medication_end,
        title: med.name,
        description: "Course completed",
        timestamp: med.end_date.to_time,
        icon: EVENT_CONFIG[:medication_end][:icon],
        severity: EVENT_CONFIG[:medication_end][:severity],
        metadata: { medication_id: med.id }
      }
    end
    events
  end

  def treatment_events
    events = []
    account.treatments.where(start_date: date_from..).find_each do |treatment|
      if treatment.start_date.present? && treatment.approved?
        events << {
          type: :treatment_started,
          title: treatment.title,
          description: treatment.description.to_s.truncate(100),
          timestamp: treatment.start_date.to_time,
          icon: EVENT_CONFIG[:treatment_started][:icon],
          severity: EVENT_CONFIG[:treatment_started][:severity],
          metadata: { treatment_id: treatment.id }
        }
      end
      if treatment.end_date.present?
        events << {
          type: :treatment_ended,
          title: treatment.title,
          description: treatment.description.to_s.truncate(100),
          timestamp: treatment.end_date.to_time,
          icon: EVENT_CONFIG[:treatment_ended][:icon],
          severity: EVENT_CONFIG[:treatment_ended][:severity],
          metadata: { treatment_id: treatment.id }
        }
      end
      treatment.updates.where(update_date: date_from..).find_each do |update|
        events << {
          type: :treatment_update,
          title: update.name,
          description: update.description,
          timestamp: update.update_date,
          icon: EVENT_CONFIG[:treatment_update][:icon],
          severity: EVENT_CONFIG[:treatment_update][:severity],
          metadata: { treatment_id: treatment.id, update_id: update.id }
        }
      end
    end
    events
  end

  def note_events
    SpecialistNote.where(account_id: account.id)
                  .where(created_at: date_from..)
                  .map do |note|
                    {
                      type: :note,
                      title: "#{note.note_type.humanize} Note",
                      description: note.content,
                      timestamp: note.created_at,
                      icon: EVENT_CONFIG[:note][:icon],
                      severity: EVENT_CONFIG[:note][:severity],
                      metadata: { note_id: note.id }
                    }
                  end
  end

  def recommendation_events
    events = []
    account.specialist_recommendations
           .where(created_at: date_from..)
           .find_each do |rec|
             newly_accepted = rec.status == "accepted" && (rec.updated_at - rec.created_at).abs < 5

             unless newly_accepted
               events << {
                 type: :recommendation_sent,
                 title: rec.name,
                 description: rec.notes.to_s.truncate(100),
                 timestamp: rec.created_at,
                 icon: EVENT_CONFIG[:recommendation_sent][:icon],
                 severity: EVENT_CONFIG[:recommendation_sent][:severity],
                 metadata: { recommendation_id: rec.id }
               }
             end

             if (rec.saved_change_to_status? || newly_accepted) && rec.status == "accepted"
               events << {
                 type: :recommendation_accepted,
                 title: "#{rec.name} accepted",
                 description: rec.notes.to_s.truncate(100),
                 timestamp: rec.updated_at,
                 icon: EVENT_CONFIG[:recommendation_accepted][:icon],
                 severity: EVENT_CONFIG[:recommendation_accepted][:severity],
                 metadata: { recommendation_id: rec.id }
               }
             elsif rec.saved_change_to_status? && rec.status.in?(%w[rejected dismissed])
               events << {
                 type: :recommendation_rejected,
                 title: "#{rec.name} declined",
                 description: rec.notes.to_s.truncate(100),
                 timestamp: rec.updated_at,
                 icon: EVENT_CONFIG[:recommendation_rejected][:icon],
                 severity: EVENT_CONFIG[:recommendation_rejected][:severity],
                 metadata: { recommendation_id: rec.id }
               }
             end
           end
    events
  end

  def message_events
    SpecialistMessage.where(account_id: account.id)
                     .where(created_at: date_from..)
                     .map do |msg|
                       {
                         type: :message,
                         title: msg.subject,
                         description: msg.body.truncate(100),
                         timestamp: msg.created_at,
                         icon: EVENT_CONFIG[:message][:icon],
                         severity: EVENT_CONFIG[:message][:severity],
                         metadata: { message_id: msg.id }
                       }
                     end
  end

  def appointment_events
    SpecialistAppointment.where(patient_id: account.id)
                         .where(appointment_date: date_from.to_date..)
                         .map do |appt|
                           {
                             type: :appointment,
                             title: "Appointment: #{appt.status.humanize}",
                             description: appt.notes.to_s.truncate(100),
                             timestamp: appt.appointment_date.to_time,
                             icon: EVENT_CONFIG[:appointment][:icon],
                             severity: EVENT_CONFIG[:appointment][:severity],
                             metadata: { appointment_id: appt.id }
                           }
                         end
  end

  def medication_request_events
    events = []
    MedicationRequest.where(account_id: account.id)
                     .where(requested_at: date_from..)
                     .find_each do |req|
                       events << {
                         type: :medication_request,
                         title: "Medication Request: #{req.medication_name}",
                         description: req.reason.to_s.truncate(100),
                         timestamp: req.requested_at,
                         icon: EVENT_CONFIG[:medication_request][:icon],
                         severity: EVENT_CONFIG[:medication_request][:severity],
                         metadata: { medication_request_id: req.id }
                       }
                       next unless req.status != "pending"

                       events << {
                         type: :medication_request_resolved,
                         title: "#{req.medication_name}: #{req.status.humanize}",
                         description: req.rejection_reason.presence || "Reviewed by specialist",
                         timestamp: req.reviewed_at || req.updated_at,
                         icon: EVENT_CONFIG[:medication_request_resolved][:icon],
                         severity: EVENT_CONFIG[:medication_request_resolved][:severity],
                         metadata: { medication_request_id: req.id }
                       }
                     end
    events
  end

  def measurement_events
    account.measurements
           .where(measurement_date: date_from..)
           .where(is_within_limits: false)
           .map do |measurement|
             {
               type: :measurement,
               title: "#{measurement.measurement_type.name.titleize}: #{measurement.value}",
               description: "Abnormal reading — #{measurement.health_risk_level}",
               timestamp: measurement.measurement_date,
               icon: EVENT_CONFIG[:measurement][:icon],
               severity: EVENT_CONFIG[:measurement][:severity],
               metadata: { measurement_id: measurement.id }
             }
           end
  end
end
