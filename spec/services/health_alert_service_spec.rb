require "rails_helper"

RSpec.describe HealthAlertService, type: :service do
  let(:account) { create(:account) }
  let(:specialist) { create(:user, account: create(:account)) }

  describe "#observe_and_assess" do
    context "when adherence risk is high" do
      before do
        allow_any_instance_of(AdherencePredictionService).to receive(:predict_non_adherence_risk).and_return({
                                                                                                               risk_level: "HIGH",
                                                                                                               risk_score: 85,
                                                                                                               risk_factors: [
                                                                                                                 "Missed doses in last 7 days", "Irregular logging pattern"
                                                                                                               ]
                                                                                                             })
      end

      it "creates a health observation log" do
        expect do
          described_class.new(account: account, specialist: specialist).observe_and_assess
        end.to change(HealthObservationLog, :count).by(1)
      end

      it "creates an emergency alert when confidence is high" do
        expect do
          described_class.new(account: account, specialist: specialist).observe_and_assess
        end.to change(EmergencyAlert, :count).by(1)
      end

      it "sets alert type to low_adherence" do
        described_class.new(account: account, specialist: specialist).observe_and_assess
        alert = EmergencyAlert.last
        expect(alert.alert_type).to eq("low_adherence")
      end

      it "includes explainable reasoning in alert message" do
        described_class.new(account: account, specialist: specialist).observe_and_assess
        alert = EmergencyAlert.last
        expect(alert.message).to include("Salus Observation")
        expect(alert.message).to include("ADHERENCE TREND")
        expect(alert.message).to include("HIGH")
        expect(alert.message).to include("Missed doses")
      end
    end

    context "when adherence risk is low" do
      before do
        allow_any_instance_of(AdherencePredictionService).to receive(:predict_non_adherence_risk).and_return({
                                                                                                               risk_level: "LOW",
                                                                                                               risk_score: 15,
                                                                                                               risk_factors: []
                                                                                                             })
      end

      it "does not create any observation" do
        expect do
          described_class.new(account: account, specialist: specialist).observe_and_assess
        end.not_to change(HealthObservationLog, :count)
      end

      it "does not create any alert" do
        expect do
          described_class.new(account: account, specialist: specialist).observe_and_assess
        end.not_to change(EmergencyAlert, :count)
      end
    end

    context "when engagement drop is detected" do
      before do
        allow_any_instance_of(AdherencePredictionService).to receive(:predict_non_adherence_risk).and_return({
                                                                                                               risk_level: "LOW",
                                                                                                               risk_score: 15,
                                                                                                               risk_factors: []
                                                                                                             })

        create(:specialist_message,
               account: account,
               specialist: specialist,
               sender_type: "patient",
               body: "Some message for engagement check",
               subject: "Test",
               created_at: 20.days.ago)
      end

      it "creates engagement_drop observation" do
        expect do
          described_class.new(account: account, specialist: specialist).observe_and_assess
        end.to change(HealthObservationLog, :count).by(1)

        log = HealthObservationLog.last
        expect(log.observation_type).to eq("engagement_drop")
      end

      it "maps engagement_drop to no_activity alert" do
        described_class.new(account: account, specialist: specialist).observe_and_assess
        alert = EmergencyAlert.last
        expect(alert.alert_type).to eq("no_activity")
      end
    end

    context "when symptom worsening is detected" do
      before do
        allow(Rails.configuration).to receive(:health_agent).and_return(
          double(observation_window_days: 14, min_confidence_threshold: 70)
        )

        allow_any_instance_of(AdherencePredictionService).to receive(:predict_non_adherence_risk).and_return({
                                                                                                               risk_level: "LOW",
                                                                                                               risk_score: 15,
                                                                                                               risk_factors: []
                                                                                                             })

        3.times do |i|
          create(:health_observation_log,
                 account: account,
                 specialist: specialist,
                 observation_type: :symptom_worsening,
                 confidence_level: i,
                 evidence: ["Symptom worsening"],
                 triggered_by: "test",
                 created_at: (3 - i).days.ago)
        end
      end

      it "detects increasing symptom severity" do
        service = described_class.new(account: account, specialist: specialist)
        observations = service.observe_and_assess
        expect(observations.pluck(:type)).to include("symptom_worsening")
      end
    end
  end

  describe "#query_patient_status" do
    let(:message) do
      create(:specialist_message, account: account, specialist: specialist, sender_type: "patient",
                                  body: "Test message", subject: "Test")
    end

    before do
      allow_any_instance_of(AdherencePredictionService).to receive(:predict_non_adherence_risk).and_return({
                                                                                                             risk_level: "MEDIUM",
                                                                                                             risk_score: 55,
                                                                                                             risk_factors: ["Inconsistent medication timing"]
                                                                                                           })

      allow_any_instance_of(PatternAnalysisService).to receive(:generate_pattern_report).and_return({
                                                                                                      summary: "Patient showing inconsistent medication timing patterns",
                                                                                                      risk_factors: ["declining"]
                                                                                                    })

      allow(SpecialistMessage).to receive(:conversation).with(account.id, specialist.id).and_return(
        SpecialistMessage.where(id: message.id)
      )
    end

    it "returns structured patient status summary" do
      result = described_class.new(account: account, specialist: specialist).query_patient_status

      expect(result).to have_key(:adherence_risk)
      expect(result).to have_key(:risk_score)
      expect(result).to have_key(:pattern_summary)
      expect(result).to have_key(:recommended_actions)
    end

    it "includes adherence risk level" do
      result = described_class.new(account: account, specialist: specialist).query_patient_status
      expect(result[:adherence_risk]).to eq("MEDIUM")
    end

    it "includes risk score" do
      result = described_class.new(account: account, specialist: specialist).query_patient_status
      expect(result[:risk_score]).to eq(55)
    end

    it "includes recommended actions" do
      result = described_class.new(account: account, specialist: specialist).query_patient_status
      expect(result[:recommended_actions]).to be_an(Array)
    end

    it "handles empty messages gracefully" do
      allow(SpecialistMessage).to receive(:conversation).and_return(SpecialistMessage.none)

      result = described_class.new(account: account, specialist: specialist).query_patient_status
      expect(result[:recent_messages_count]).to eq(0)
      expect(result[:last_contact]).to be_nil
    end
  end

  describe "confidence threshold" do
    it "uses config value for min_confidence_threshold" do
      allow(Rails.configuration).to receive(:health_agent).and_return(
        double(min_confidence_threshold: 50, observation_window_days: 14)
      )

      allow_any_instance_of(AdherencePredictionService).to receive(:predict_non_adherence_risk).and_return({
                                                                                                             risk_level: "HIGH",
                                                                                                             risk_score: 85,
                                                                                                             risk_factors: ["Test factor"]
                                                                                                           })

      expect do
        described_class.new(account: account, specialist: specialist).observe_and_assess
      end.to change(EmergencyAlert, :count).by(1)
    end
  end
end
