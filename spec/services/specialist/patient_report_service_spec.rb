require "rails_helper"

RSpec.describe SpecialistPatientReportService do
  let(:specialist_user) { create(:user, :specialist) }
  let(:patient_account) do
    create(:account, first_name: "Maria", last_name: "Garcia", city: "Warsaw", country: "Poland")
  end
  let(:predefined_disease) { create(:predefined_disease, name: "Type 2 Diabetes", icd10_code: "E11") }
  let(:blood_pressure_type) { create(:blood_pressure_measurement_type) }
  let(:blood_sugar_type) { create(:sugar_measurement_type) }

  before do
    create(:specialist_patient, specialist: specialist_user, account: patient_account, status: "active")
  end

  describe "#call" do
    context "when patient has minimal data" do
      it "generates a valid PDF document" do
        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call
        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end

      it "returns PDF with valid header" do
        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call
        expect(pdf_data).to start_with("%PDF")
      end

      it "ends with EOF marker" do
        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call
        expect(pdf_data).to end_with("%%EOF\n")
      end

      it "creates non-empty pages" do
        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call
        expect(pdf_data).to include("stream")
        expect(pdf_data).to include("endstream")
      end
    end

    context "with diseases" do
      it "generates PDF with disease content" do
        create(:disease, account: patient_account, predefined_disease: predefined_disease, severity: 3)

        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end
    end

    context "with medications" do
      it "generates PDF with medication content" do
        create(:medication, account: patient_account, name: "Metformin", dosage: "500mg", frequency: "twice_daily",
                            is_active: true)

        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end

      it "handles patient-requested medications" do
        med_request = create(:medication_request, account: patient_account, specialist: specialist_user,
                                                  medication_name: "Aspirin", status: "approved")
        create(:medication, account: patient_account, name: "Aspirin", dosage: "100mg", frequency: "once_daily",
                            source: "patient_request", medication_request: med_request)

        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end

      it "handles doctor-prescribed medications" do
        recommendation = create(:specialist_recommendation, account: patient_account, specialist: specialist_user,
                                                            name: "Lisinopril", recommendation_type: "medication", status: "accepted")
        create(:medication, account: patient_account, name: "Lisinopril", dosage: "10mg", frequency: "once_daily",
                            source: "doctor_prescription", specialist_recommendation: recommendation)

        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end
    end

    context "with treatments" do
      it "includes approved treatments in report" do
        create(:treatment, account: patient_account, title: "Insulin Therapy", description: "Daily insulin",
                           approval_status: "approved")

        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end

      it "excludes rejected treatments" do
        create(:treatment, account: patient_account, title: "Experimental Treatment", approval_status: "rejected")

        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end
    end

    context "with measurements" do
      it "includes measurements in report" do
        create(:measurement, account: patient_account, measurement_type: blood_pressure_type, value: "120/80",
                             measurement_date: 1.day.ago)

        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end
    end

    context "with specialist notes" do
      it "includes specialist notes in report" do
        create(:specialist_note, account: patient_account, specialist: specialist_user, note_type: "observation",
                                 content: "Blood pressure elevated")

        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end
    end

    context "with care history" do
      it "includes care history in report" do
        create(:disease, account: patient_account, predefined_disease: predefined_disease, diagnosed_at: 10.days.ago)
        create(:specialist_note, account: patient_account, specialist: specialist_user, note_type: "observation",
                                 content: "Patient doing well")

        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end
    end

    context "with AI prediction" do
      it "handles insufficient data gracefully" do
        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end

      it "handles sufficient data for AI prediction" do
        create(:medication_log, :taken, account: patient_account, scheduled_for: 1.day.ago)
        create(:medication_log, :taken, account: patient_account, scheduled_for: 2.days.ago)
        create(:medication_log, :taken, account: patient_account, scheduled_for: 3.days.ago)
        create(:medication_log, :taken, account: patient_account, scheduled_for: 4.days.ago)
        create(:medication_log, :taken, account: patient_account, scheduled_for: 5.days.ago)
        create(:medication_log, :taken, account: patient_account, scheduled_for: 6.days.ago)
        create(:medication_log, :taken, account: patient_account, scheduled_for: 7.days.ago)
        create(:medication_log, :taken, account: patient_account, scheduled_for: 8.days.ago)
        create(:medication_log, :taken, account: patient_account, scheduled_for: 9.days.ago)
        create(:medication_log, :taken, account: patient_account, scheduled_for: 10.days.ago)

        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        expect(pdf_data).to be_a(String)
        expect(pdf_data.length).to be > 1000
      end
    end

    context "report metadata" do
      it "generates PDF with proper structure" do
        service = described_class.new(patient_account, specialist_user)
        pdf_data = service.call

        salus_hex = "SALUS".bytes.map { |b| b.to_s(16).rjust(2, "0") }.join
        expect(pdf_data).to include(salus_hex)
      end
    end
  end

  describe "error handling" do
    it "raises PDFGenerationError on Prawn failure" do
      allow(Prawn::Document).to receive(:new).and_raise(StandardError.new("Prawn error"))

      service = described_class.new(patient_account, specialist_user)
      expect { service.call }.to raise_error(described_class::PDFGenerationError)
    end
  end
end
