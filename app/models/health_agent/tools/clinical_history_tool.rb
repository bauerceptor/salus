module HealthAgent
  module Tools
    class ClinicalHistoryTool < RubyLLM::Tool
      description "Get comprehensive clinical history summary for a patient"

      param :patient_id, type: "string", desc: "The patient's account UUID", required: true

      def execute(patient_id:)
        account = Account.find_by(id: patient_id)
        return { "error" => "Patient not found with ID: #{patient_id}" } unless account

        build_clinical_summary(account)
      end

      private

      def build_clinical_summary(account)
        conditions_count = account.diseases.count
        medications_count = account.medications.active.count

        from_date = 90.days.ago
        measurements = account.measurements
                              .where(measurement_date: from_date..)
                              .order(measurement_date: :desc)

        recent_measurements_count = measurements.count

        adherence_rate = calculate_adherence_rate(account)

        {
          "account_id" => account.id,
          "conditions_count" => conditions_count,
          "medications_count" => medications_count,
          "recent_measurements_count" => recent_measurements_count,
          "adherence_rate" => adherence_rate
        }
      end

      def calculate_adherence_rate(account)
        recent_logs = MedicationLog.for_account(account).where(scheduled_for: 30.days.ago..)
        total = recent_logs.count
        return 100.0 if total.zero?

        taken = recent_logs.taken.count
        ((taken.to_f / total) * 100).round(2)
      end
    end
  end
end
