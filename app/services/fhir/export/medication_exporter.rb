# frozen_string_literal: true

module Fhir
  module Export
    class MedicationExporter
      def initialize(medication)
        @medication = medication
      end

      def to_fhir
        return nil if @medication.blank?

        FHIR::MedicationStatement.new(
          id: @medication.id,
          status: @medication.is_active? ? "active" : "completed",
          statusReason: @medication.is_active? ? nil : build_status_reason,
          medicationCodeableConcept: build_medication,
          subject: reference_to_patient,
          effectiveDateTime: effective_date,
          effectivePeriod: effective_period,
          dosage: build_dosage,
          note: build_note
        )
      end

      def to_fhir_json
        to_fhir&.to_json
      end

      private

      def reference_to_patient
        return nil unless @medication.account_id

        FHIR::Reference.new(
          reference: "Patient/#{@medication.account_id}"
        )
      end

      def effective_date
        return nil unless @medication.start_date

        @medication.start_date.iso8601
      end

      def effective_period
        return nil unless @medication.start_date || @medication.end_date

        FHIR::Period.new(
          start: @medication.start_date&.iso8601,
          end: @medication.end_date&.iso8601
        )
      end

      def build_medication
        FHIR::CodeableConcept.new(
          coding: build_coding,
          text: @medication.name
        )
      end

      def build_coding
        codes = []

        if rxnorm_code
          codes << FHIR::Coding.new(
            system: "http://www.nlm.nih.gov/research/umls/rxnorm",
            code: rxnorm_code,
            display: @medication.name
          )
        end

        codes << FHIR::Coding.new(
          system: "http://example.org/medication",
          code: @medication.id.to_s,
          display: "#{@medication.name} #{@medication.dosage}"
        )

        codes
      end

      def rxnorm_code
        Fhir::Codes::RxnormCodes.for(@medication.name)&.dig(:code)
      end

      def build_dosage
        dosage_text = @medication.dosage.to_s
        frequency_text = frequency_text

        FHIR::Dosage.new(
          text: "#{dosage_text} #{frequency_text}".strip,
          timing: build_timing,
          doseAndRate: [
            {
              doseQuantity: FHIR::Quantity.new(
                value: parse_dosage_value,
                unit: parse_dosage_unit,
                system: "http://unitsofmeasure.org"
              )
            }
          ]
        )
      end

      def frequency_text
        case @medication.frequency
        when 0 then "once daily"
        when 1 then "twice daily"
        when 2 then "three times daily"
        when 3 then "four times daily"
        when 4 then "as needed"
        when 5 then "weekly"
        when 6 then "monthly"
        else "as directed"
        end
      end

      def build_timing
        FHIR::Timing.new(
          code: FHIR::CodeableConcept.new(
            text: frequency_text
          )
        )
      end

      def parse_dosage_value
        return nil unless @medication.dosage

        @medication.dosage.to_s.gsub(/[^\d.]/, "").to_f
      rescue StandardError
        nil
      end

      def parse_dosage_unit
        return nil unless @medication.dosage

        @medication.dosage.to_s.gsub(/[\d\s]/, "")
      rescue StandardError
        nil
      end

      def build_status_reason
        [FHIR::CodeableConcept.new(
          text: "Treatment completed or stopped"
        )]
      end

      def build_note
        return nil if @medication.instructions.blank?

        [FHIR::Annotation.new(text: @medication.instructions)]
      end
    end
  end
end
