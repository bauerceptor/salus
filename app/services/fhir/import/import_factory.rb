# frozen_string_literal: true

require "fhir"

module Fhir
  module Import
    class ImportFactory
      IMPORTERS = {
        "Observation" => ObservationImporter,
        "Condition" => ConditionImporter,
        "MedicationStatement" => MedicationImporter,
        "Bundle" => BundleImporter
      }.freeze

      def self.for(resource_type, fhir_resource, account_id)
        importer_class = IMPORTERS[resource_type]
        raise Fhir::ImportError, "Unknown resource type: #{resource_type}" unless importer_class

        importer_class.new(fhir_resource, account_id)
      end

      def self.supported_types
        IMPORTERS.keys
      end

      def self.from_file(file_path, account_id)
        json_content = File.read(file_path)
        fhir_resource = JSON.parse(json_content, object_class: OpenStruct)

        resource_type = fhir_resource.resourceType

        if resource_type == "Bundle"
          bundle = FHIR::Bundle.new(fhir_resource.to_h)
          BundleImporter.new(bundle, account_id)
        else
          klass = "FHIR::#{resource_type}".constantize
          resource = klass.new(fhir_resource.to_h)
          self.for(resource_type, resource, account_id)
        end
      rescue StandardError => e
        raise Fhir::ImportError, "Failed to parse FHIR file: #{e.message}"
      end
    end
  end
end
