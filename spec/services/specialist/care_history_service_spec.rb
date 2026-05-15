require "rails_helper"

RSpec.describe PatientCareHistoryService do
  let(:patient) { create(:account, first_name: "Maria", last_name: "Garcia") }
  let(:specialist_user) { create(:user, :specialist) }
  let(:predefined_disease) { create(:predefined_disease, name: "Type 2 Diabetes", icd10_code: "E11") }

  describe "#events" do
    it "returns an empty array when patient has no events" do
      service = described_class.new(patient)
      expect(service.events).to eq([])
    end

    it "returns events sorted reverse-chronologically" do
      create(:disease, account: patient, predefined_disease: predefined_disease, diagnosed_at: 10.days.ago)
      SpecialistNote.create!(account: patient, specialist: specialist_user, content: "Follow-up visit",
                             created_at: 5.days.ago)

      service = described_class.new(patient)
      events = service.events

      expect(events.first[:type]).to eq(:note)
      expect(events.last[:type]).to eq(:diagnosis)
    end

    it "includes diagnosis events from Disease records" do
      create(:disease, account: patient, predefined_disease: predefined_disease, diagnosed_at: 2.days.ago)

      service = described_class.new(patient)
      events = service.events

      diagnosis_event = events.find { |e| e[:type] == :diagnosis }
      expect(diagnosis_event).to be_present
      expect(diagnosis_event[:title]).to include("Type 2 Diabetes")
      expect(diagnosis_event[:timestamp]).to be_a(ActiveSupport::TimeWithZone).or(be_a(Time))
    end

    it "includes medication_start events from Medications" do
      Medication.create!(account: patient, name: "Metformin", dosage: "500mg", frequency: "twice_daily",
                         is_active: true, start_date: 3.days.ago.to_date)

      service = described_class.new(patient)
      events = service.events

      med_event = events.find { |e| e[:type] == :medication_start }
      expect(med_event).to be_present
      expect(med_event[:title]).to include("Metformin")
      expect(med_event[:description]).to include("500mg")
    end

    it "includes medication_end events when Medication has an end_date" do
      Medication.create!(account: patient, name: "Aspirin", dosage: "100mg", frequency: "once_daily", is_active: false,
                         end_date: 1.day.ago)

      service = described_class.new(patient)
      events = service.events

      med_end_event = events.find { |e| e[:type] == :medication_end }
      expect(med_end_event).to be_present
      expect(med_end_event[:title]).to include("Aspirin")
    end

    it "includes treatment_started events from approved Treatments" do
      Treatment.create!(
        account: patient,
        title: "Insulin Therapy",
        description: "Daily insulin injections",
        start_date: 3.days.ago.to_date,
        effectiveness: 3,
        approval_status: "approved"
      )

      service = described_class.new(patient)
      events = service.events

      treatment_event = events.find { |e| e[:type] == :treatment_started }
      expect(treatment_event).to be_present
      expect(treatment_event[:title]).to include("Insulin Therapy")
    end

    it "includes treatment_update events from TreatmentUpdates" do
      treatment = Treatment.create!(
        account: patient,
        title: "Physical Therapy",
        description: "Leg exercises",
        start_date: 15.days.ago.to_date,
        effectiveness: 3,
        approval_status: "approved"
      )
      create(:treatment_update, treatment: treatment, name: "Progress check",
                                description: "Patient showing improvement", status: "improvement", update_date: 2.days.ago)

      service = described_class.new(patient)
      events = service.events

      update_event = events.find { |e| e[:type] == :treatment_update }
      expect(update_event).to be_present
      expect(update_event[:title]).to include("Progress check")
    end

    it "includes note events from SpecialistNotes" do
      SpecialistNote.create!(account: patient, specialist: specialist_user, note_type: "observation",
                             content: "Patient reports feeling better", created_at: 1.day.ago)

      service = described_class.new(patient)
      events = service.events

      note_event = events.find { |e| e[:type] == :note }
      expect(note_event).to be_present
      expect(note_event[:title]).to eq("Observation Note")
      expect(note_event[:description]).to include("Patient reports feeling better")
    end

    it "includes recommendation_sent events from SpecialistRecommendations" do
      create(:specialist_recommendation, account: patient, specialist: specialist_user, name: "Metformin 1000mg",
                                         recommendation_type: "medication", status: "pending", created_at: 4.days.ago)

      service = described_class.new(patient)
      events = service.events

      rec_sent = events.find { |e| e[:type] == :recommendation_sent }
      expect(rec_sent).to be_present
      expect(rec_sent[:title]).to include("Metformin 1000mg")
    end

    it "includes recommendation_accepted events when SpecialistRecommendation status transitions to accepted" do
      rec = SpecialistRecommendation.new(account: patient, specialist: specialist_user, name: "New Supplement",
                                         recommendation_type: "medication", status: "pending")
      rec.save!
      rec.update!(status: "accepted")

      service = described_class.new(patient)
      events = service.events

      rec_accepted = events.find { |e| e[:type] == :recommendation_accepted }
      expect(rec_accepted).to be_present
      expect(rec_accepted[:title]).to include("New Supplement")
    end

    it "includes message events from SpecialistMessages" do
      SpecialistMessage.create!(account: patient, specialist: specialist_user, sender_type: "patient",
                                subject: "Question about dosage", body: "Is it safe to take with food?", created_at: 1.day.ago)

      service = described_class.new(patient)
      events = service.events

      message_event = events.find { |e| e[:type] == :message }
      expect(message_event).to be_present
      expect(message_event[:title]).to eq("Question about dosage")
    end

    it "includes appointment events from SpecialistAppointments" do
      specialist = create(:specialist, user: specialist_user)
      schedule = create(:specialist_schedule, specialist: specialist, is_active: true)
      SpecialistAppointment.create!(patient: patient, specialist: specialist, schedule: schedule,
                                    appointment_date: 2.days.from_now.to_date, status: "scheduled", start_time: "09:00", end_time: "09:30")

      service = described_class.new(patient)
      events = service.events

      appt_event = events.find { |e| e[:type] == :appointment }
      expect(appt_event).to be_present
    end

    it "includes medication_request events from MedicationRequests" do
      create(:medication_request, account: patient, specialist: specialist_user, medication_name: "GLP-1 Agonist",
                                  status: "pending", requested_at: 1.day.ago)

      service = described_class.new(patient)
      events = service.events

      med_req_event = events.find { |e| e[:type] == :medication_request }
      expect(med_req_event).to be_present
      expect(med_req_event[:title]).to include("GLP-1 Agonist")
    end

    it "includes abnormal Measurement events" do
      measurement_type = create(:sugar_measurement_type)
      Measurement.create!(
        account: patient,
        measurement_type: measurement_type,
        value: "250",
        measurement_date: 1.day.ago,
        is_within_limits: false
      )

      service = described_class.new(patient)
      events = service.events

      measurement_event = events.find { |e| e[:type] == :measurement }
      expect(measurement_event).to be_present
      expect(measurement_event[:title]).to include("Sugar")
    end

    it "excludes normal (non-abnormal) Measurements" do
      measurement_type = create(:sugar_measurement_type)
      Measurement.create!(
        account: patient,
        measurement_type: measurement_type,
        value: "120",
        measurement_date: 1.day.ago,
        is_within_limits: true
      )

      service = described_class.new(patient)
      events = service.events

      expect(events.pluck(:type)).not_to include("measurement")
    end

    it "only returns events from the last 30 days by default (recent scope)" do
      create(:disease, account: patient, predefined_disease: predefined_disease,
                       diagnosed_at: 60.days.ago)
      SpecialistNote.create!(account: patient, specialist: specialist_user, content: "Recent note",
                             created_at: 5.days.ago)

      service = described_class.new(patient)
      events = service.events

      expect(events.pluck(:type)).to include(:note)
      expect(events.pluck(:type)).not_to include(:diagnosis)
    end

    it "returns all events when scope is :full" do
      create(:disease, account: patient, predefined_disease: predefined_disease, diagnosed_at: 60.days.ago)
      SpecialistNote.create!(account: patient, specialist: specialist_user, content: "Recent note",
                             created_at: 5.days.ago)

      service = described_class.new(patient, scope: :full)
      events = service.events

      expect(events.pluck(:type)).to include(:diagnosis)
      expect(events.pluck(:type)).to include(:note)
    end

    it "returns events with correct structure" do
      SpecialistNote.create!(account: patient, specialist: specialist_user, note_type: "warning",
                             content: "Blood pressure elevated", created_at: 1.day.ago)

      service = described_class.new(patient)
      event = service.events.first

      expect(event.keys).to match_array(%i[type title description timestamp icon severity metadata])
      expect(event[:type]).to be_a(Symbol)
      expect(event[:title]).to be_a(String)
      expect(event[:timestamp]).to be_a(ActiveSupport::TimeWithZone)
      expect(event[:icon]).to be_a(String)
      expect(event[:severity]).to be_a(String)
    end
  end
end
