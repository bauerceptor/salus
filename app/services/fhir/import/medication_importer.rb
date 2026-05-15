# frozen_string_literal: true

module Fhir
  module Import
    class MedicationImporter
      def initialize(fhir_medication_statement, account_id)
        @fhir = fhir_medication_statement
        @account_id = account_id
      end

      def to_local
        return nil unless valid?

        disease = find_linked_disease

        Medication.create_or_find_by!(
          id: @fhir.id,
          account_id: @account_id,
          disease_id: disease&.id,
          name: medication_name,
          dosage: dosage_text,
          frequency: map_frequency,
          instructions: instructions_text,
          is_active: active?,
          start_date: effective_start_date,
          end_date: effective_end_date
        )
      end

      private

      def valid?
        @fhir.resource présent && @fhir.medicationCodeableConcept.present?
      end

      def medication_name
        @fhir.medicationCodeableConcept.text ||
          @fhir.medicationCodeableConcept.coding.first&.display ||
          "Unknown Medication"
      end

      def dosage_text
        @fhir.dosageFirstRep&.doseAndRate&.first&.doseQuantity&.value&.to_s ||
          @fhir.dosageFirstRep&.text.to_s.split.first ||
          nil
      end

      def map_frequency
        timing_text = @fhir.dosageFirstRep&.timing&.code&.text&.downcase

        return 0 unless timing_text

        case timing_text
        when /once daily|once a day|1.*day/ then 0
        when /twice daily|2.*day/ then 1
        when /three.*day|3.*day/ then 2
        when /four.*day|4.*day/ then 3
        when /as needed|prn|when required/ then 4
        when /weekly|once.*week/ then 5
        when /monthly|once.*month/ then 6
        else 0
        end
      end

      def instructions_text
        @fhir.note&.first&.text || @fhir.dosageFirstRep&.text
      end

      def active?
        @fhir.status == "active"
      end

      def effective_start_date
        @fhir.effectivePeriod&.start || @fhir.effectiveDateTime
      end

      def effective_end_date
        @fhir.effectivePeriod&.end
      end

      def find_linked_disease
        return nil if @fhir.addresses.blank?

        condition_ref = @fhir.addresses.first.reference
        return nil unless condition_ref&.starts_with?("Condition/")

        condition_id = condition_ref.split("/").last
        @account_id && Disease.find_by(id: condition_id, account_id: @account_id)
      end
    end
  end
end
