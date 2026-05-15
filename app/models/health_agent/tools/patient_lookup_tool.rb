module HealthAgent
  module Tools
    class PatientLookupTool < RubyLLM::Tool
      description "Look up patient profile and recent health history"

      param :patient_id, type: "string", desc: "The patient's account UUID", required: true

      def execute(patient_id:)
        account = Account.find_by(id: patient_id)
        return { "error" => "Patient not found with ID: #{patient_id}" } unless account

        build_patient_summary(account)
      end

      private

      def build_patient_summary(account)
        {
          account_id: account.id,
          name: account.full_name,
          location: "#{account.city}, #{account.country}",
          risk_level: account.risk_level || "UNKNOWN",
          risk_score: account.risk_score || 0,
          medications: account.medications.active.count,
          diseases: account.diseases.count,
          recent_measurements: build_recent_measurements(account),
          last_activity: account.updated_at
        }.stringify_keys
      end

      def build_recent_measurements(account)
        recent = account.measurements
                        .order(measurement_date: :desc)
                        .limit(5)
                        .includes(:measurement_type)

        recent.map do |m|
          {
            type: m.measurement_type.name,
            value: m.value,
            unit: m.measurement_type.unit.symbol,
            date: m.measurement_date.iso8601
          }
        end
      end
    end
  end
end
