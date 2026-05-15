# frozen_string_literal: true

require "fhir"

module Fhir
  module Export
    class ObservationExporter
      def initialize(measurement)
        @measurement = measurement
      end

      def to_fhir
        return nil if @measurement.blank?

        loinc = Codes::LoincCodes.for(@measurement.measurement_type.name)

        FHIR::Observation.new(
          id: @measurement.id,
          status: @measurement.is_within_limits ? "final" : "final",
          category: [
            FHIR::CodeableConcept.new(
              coding: [
                FHIR::Coding.new(
                  system: "http://terminology.hl7.org/CodeSystem/observation-category",
                  code: "vital-signs",
                  display: "Vital Signs"
                )
              ]
            )
          ],
          code: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: loinc[:system],
                code: loinc[:code],
                display: loinc[:display]
              )
            ],
            text: @measurement.measurement_type.name.humanize
          ),
          subject: reference_to_patient,
          effectiveDateTime: @measurement.measurement_date.iso8601,
          valueQuantity: build_value_quantity(loinc),
          note: build_note
        )
      end

      def to_fhir_json
        to_fhir&.to_json
      end

      private

      def reference_to_patient
        return nil unless @measurement.account_id

        FHIR::Reference.new(
          reference: "Patient/#{@measurement.account_id}"
        )
      end

      def build_value_quantity(loinc)
        value = @measurement.value
        unit_symbol = @measurement.measurement_type.unit&.symbol || loinc[:unit]

        FHIR::Quantity.new(
          value: parse_value(value),
          unit: unit_symbol,
          system: "http://unitsofmeasure.org",
          code: unit_symbol
        )
      end

      def parse_value(value)
        return nil if value.nil?

        if value.to_s.include?("/")
          value.to_s.split("/").first.to_f
        else
          value.to_s.to_f
        end
      rescue StandardError
        nil
      end

      def build_note
        return nil if @measurement.is_within_limits

        [FHIR::Annotation.new(
          text: "Value outside normal limits. Normal range: #{@measurement.measurement_type.lower_limit} - #{@measurement.measurement_type.upper_limit}"
        )]
      end
    end
  end
end
