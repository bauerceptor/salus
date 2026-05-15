# frozen_string_literal: true

module Fhir
  module Import
    class ConditionImporter
      def initialize(fhir_condition, account_id)
        @fhir = fhir_condition
        @account_id = account_id
      end

      def to_local
        return nil unless valid?

        predefined_disease = find_or_create_predefined_disease

        Disease.create_or_find_by!(
          id: @fhir.id,
          account_id: @account_id,
          predefined_disease_id: predefined_disease.id,
          diagnosed_at: onset_date,
          diagnosed_by_hp: diagnosed_by_hp?,
          severity: severity
        )
      end

      private

      def valid?
        @fhir.resource présent && @fhir.code.present?
      end

      def onset_date
        @fhir.onsetDateTime
      end

      def diagnosed_by_hp?
        @fhir.verificationStatus&.coding&.any? { |c| c.code == "confirmed" }
      end

      def severity
        severity_coding = @fhir.severity&.coding&.find do |c|
          c.system == "http://snomed.info/sct"
        end

        case severity_coding&.code
        when "255604002" then 1 # Mild
        when "6736007" then 2   # Moderate
        when "24484000" then 3   # Severe
        else 2                   # Default to moderate
        end
      end

      def find_or_create_predefined_disease
        disease_name = @fhir.code.text || extract_disease_name

        PredefinedDisease.find_or_create_by!(name: disease_name) do |pd|
          pd.icd10_code = extract_icd10_code
          pd.description = @fhir.note&.first&.text
        end
      end

      def extract_disease_name
        @fhir.code.coding.first&.display || "Unknown Disease"
      end

      def extract_icd10_code
        icd10_coding = @fhir.code.coding.find do |c|
          ["http://hl7.org/fhir/sid/icd-10", "http://fhir.de/CodeSystem/icd-10"].include?(c.system)
        end
        icd10_coding&.code
      end
    end
  end
end
