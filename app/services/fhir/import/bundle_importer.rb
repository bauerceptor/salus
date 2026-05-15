# frozen_string_literal: true

module Fhir
  module Import
    class BundleImporter
      def initialize(fhir_bundle, account_id, uploaded_by_id: nil)
        @bundle = fhir_bundle
        @account_id = account_id
        @uploaded_by_id = uploaded_by_id
      end

      def import_all
        results = {
          observations: [],
          conditions: [],
          medications: [],
          documents: [],
          errors: []
        }

        return results unless valid_bundle?

        @bundle.entry.each do |entry|
          resource = entry.resource
          case resource.resourceType
          when "Observation"
            result = ObservationImporter.new(resource, @account_id).to_local
            results[:observations] << result if result
          when "Condition"
            result = ConditionImporter.new(resource, @account_id).to_local
            results[:conditions] << result if result
          when "MedicationStatement"
            result = MedicationImporter.new(resource, @account_id).to_local
            results[:medications] << result if result
          when "DocumentReference"
            result = DocumentReferenceImporter.new(resource, @account_id, @uploaded_by_id).to_local
            results[:documents] << result if result
          when "Patient"
            # Patient import not supported yet - would need special handling
          end
        rescue StandardError => e
          results[:errors] << {
            resource_type: entry.resource.resourceType,
            id: entry.resource.id,
            error: e.message
          }
        end

        results
      end

      def self.from_json(json_string, account_id, uploaded_by_id: nil)
        fhir_bundle = FHIR::Bundle.new(JSON.parse(json_string))
        new(fhir_bundle, account_id, uploaded_by_id: uploaded_by_id)
      end

      private

      def valid_bundle?
        @bundle.present? && @bundle.entry.present?
      end
    end
  end
end
