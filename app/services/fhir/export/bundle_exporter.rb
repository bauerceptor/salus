# frozen_string_literal: true

module Fhir
  module Export
    class BundleExporter
      def initialize(account)
        @account = account
      end

      def to_fhir
        FHIR::Bundle.new(
          id: "salus-export-#{@account.id}-#{Time.zone.now.strftime('%Y%m%d%H%M%S')}",
          type: "collection",
          timestamp: Time.now.iso8601,
          total: resources.count,
          entry: build_entries
        )
      end

      def to_fhir_json
        to_fhir.to_json
      end

      def export_to_file(directory_path = nil)
        filename = "fhir_bundle_#{@account.username}_#{Time.zone.now.strftime('%Y%m%d')}.json"
        file_path = directory_path ? File.join(directory_path, filename) : filename

        File.write(file_path, to_fhir_json)
        file_path
      end

      private

      def resources
        @resources ||= build_resources
      end

      def build_resources
        result = []

        result << patient_resource
        result += measurement_resources
        result += disease_resources
        result += medication_resources
        result += treatment_resources

        result.compact
      end

      def build_entries
        resources.map do |resource|
          FHIR::Bundle::Entry.new(
            resource: resource,
            fullUrl: "#{resource.resourceType}/#{resource.id}"
          )
        end
      end

      def patient_resource
        PatientExporter.new(@account).to_fhir
      end

      def measurement_resources
        @account.measurements.includes(:measurement_type).filter_map do |m|
          ObservationExporter.new(m).to_fhir
        end
      end

      def disease_resources
        @account.diseases.includes(:predefined_disease).filter_map do |d|
          ConditionExporter.new(d).to_fhir
        end
      end

      def medication_resources
        @account.medications.filter_map do |m|
          MedicationExporter.new(m).to_fhir
        end
      end

      def treatment_resources
        @account.treatments.includes(:diseases).filter_map do |t|
          CarePlanExporter.new(t).to_fhir
        end
      end
    end
  end
end
