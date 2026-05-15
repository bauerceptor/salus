# frozen_string_literal: true

require "fhir"

module Fhir
  module Export
    class ExporterFactory
      RESOURCE_TYPES = {
        "Observation" => ObservationExporter,
        "Condition" => ConditionExporter,
        "MedicationStatement" => MedicationExporter,
        "CarePlan" => CarePlanExporter,
        "Patient" => PatientExporter
      }.freeze

      def self.for(resource_type, model)
        exporter_class = RESOURCE_TYPES[resource_type]
        raise Fhir::ExportError, "Unknown resource type: #{resource_type}" unless exporter_class

        exporter_class.new(model)
      end

      def self.supported_types
        RESOURCE_TYPES.keys
      end
    end
  end
end
