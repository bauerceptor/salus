module HealthAgent
  module Tools
    class AdherenceSummaryTool < RubyLLM::Tool
      description "Get medication adherence summary for a patient"

      param :patient_id, type: "string", desc: "The patient's account UUID", required: true

      def execute(patient_id:)
        account = Account.find_by(id: patient_id)
        return { "error" => "Patient not found with ID: #{patient_id}" } unless account

        build_adherence_summary(account)
      end

      private

      def build_adherence_summary(account)
        active_meds = account.medications.active
        total = active_meds.count
        if total.zero?
          return { "account_id" => account.id, "total_medications" => 0, "active_medications" => 0,
                   "overall_adherence" => 100.0, "taken_count" => 0, "missed_count" => 0 }.stringify_keys
        end

        taken = 0
        missed = 0
        active_meds.each do |med|
          taken += med.medication_logs.where(status: :taken).count
          missed += med.medication_logs.where(status: :missed).count
        end

        total_logs = taken + missed
        adherence = total_logs.zero? ? 100.0 : (taken.to_f / total_logs * 100).round(2)

        {
          "account_id" => account.id,
          "total_medications" => total,
          "active_medications" => total,
          "taken_count" => taken,
          "missed_count" => missed,
          "overall_adherence" => adherence
        }
      end
    end
  end
end
