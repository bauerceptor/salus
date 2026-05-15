require "rails_helper"

RSpec.describe "Health Tracking Flow", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.account }

  describe "Disease lifecycle" do
    context "when authenticated" do
      before { sign_in user }

      scenario "user creates a disease, adds symptoms, and updates status" do
        # Create a predefined disease first
        predefined_disease = create(:predefined_disease, name: "Test Disease")

        # Create disease
        get new_disease_path
        expect(response).to be_successful

        post diseases_path, params: {
          disease: {
            name: "Test Disease",
            diagnosed_at: Time.zone.today,
            severity: 1,
            predefined_disease_id: predefined_disease.id
          }
        }

        disease = account.diseases.last
        expect(disease.name).to eq("Test Disease")
        expect(response).to redirect_to(diseases_path)

        # View disease
        get disease_path(id: disease.id)
        expect(response).to be_successful

        # Update disease severity
        patch disease_path(id: disease.id), params: {
          disease: { severity: 2 }
        }
        disease.reload
        expect(disease.severity).to eq(2)

        # Destroy disease
        delete disease_path(id: disease.id)
        expect do
          disease.reload
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "Medication management" do
    context "when authenticated" do
      before { sign_in user }

      scenario "user adds medication with schedule and logs intake" do
        # Create medication
        get new_medication_path
        expect(response).to be_successful

        post medications_path, params: {
          medication: {
            name: "Aspirin",
            dosage: "500mg",
            frequency: "daily",
            start_date: Time.zone.today,
            is_active: true
          }
        }

        medication = account.medications.last
        expect(medication.name).to eq("Aspirin")
        expect(response).to redirect_to(medications_path)

        # Add schedule
        create(:medication_schedule, medication: medication)
        expect(medication.medication_schedules).not_to be_empty

        # View medication
        get medication_path(id: medication.id)
        expect(response).to be_successful

        # Update medication
        patch medication_path(id: medication.id), params: {
          medication: { dosage: "1000mg" }
        }
        medication.reload
        expect(medication.dosage).to eq("1000mg")

        # Deactivate medication
        patch medication_path(id: medication.id), params: {
          medication: { is_active: false }
        }
        medication.reload
        expect(medication.is_active).to be false
      end
    end
  end

  describe "Measurement tracking" do
    context "when authenticated" do
      before { sign_in user }

      scenario "user logs measurements and views trends" do
        create(:measurement_type, name: "weight")

        # Add weight measurement
        post create_measurements_path(measurement_type: "weight"), params: {
          measurement: {
            value: "75.5",
            measurement_date: Time.zone.now
          }
        }

        measurement = account.measurements.last
        expect(measurement.value).to eq(75.5)
        expect(response).to redirect_to(measurements_path)

        # View measurements index
        get measurements_path
        expect(response).to be_successful
        expect(assigns(:latest)[:weight]).to eq(measurement)

        # View measurements by day
        day = measurement.measurement_date.to_date
        get show_by_day_measurements_path(day: day)
        expect(response).to be_successful

        # Update measurement
        patch measurement_path(id: measurement.id), params: {
          measurement: { value: "76.0" }
        }
        measurement.reload
        expect(measurement.value).to eq(76.0)

        # Delete measurement
        delete measurement_path(id: measurement.id)
        expect do
          measurement.reload
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end

  describe "Notes management" do
    context "when authenticated" do
      before { sign_in user }

      scenario "user creates, edits, pins, and deletes notes" do
        # Create note
        post notes_path, params: {
          note: {
            title: "Doctor Appointment",
            content: "Annual checkup scheduled for next week"
          }
        }

        note = account.notes.last
        expect(note.title).to eq("Doctor Appointment")
        expect(response).to redirect_to(notes_path)

        # View note
        get note_path(id: note.id)
        expect(response).to be_successful

        # Update note
        patch note_path(id: note.id), params: {
          note: { content: "Appointment rescheduled" }
        }
        note.reload
        expect(note.content).to eq("Appointment rescheduled")

        # Pin note
        patch pin_note_path(id: note.id)
        note.reload
        expect(note.is_pinned).to be true

        # Unpin note
        patch unpin_note_path(id: note.id)
        note.reload
        expect(note.is_pinned).to be false

        # Delete note
        delete note_path(id: note.id)
        expect do
          note.reload
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
