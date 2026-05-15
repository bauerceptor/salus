# frozen_string_literal: true

module Fhir
  module Export
    class ConditionExporter
      def initialize(disease)
        @disease = disease
      end

      def to_fhir
        return nil if @disease.blank?

        FHIR::Condition.new(
          id: @disease.id,
          clinicalStatus: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "http://terminology.hl7.org/CodeSystem/condition-clinical",
                code: clinical_status_code,
                display: clinical_status_code.titleize
              )
            ]
          ),
          verificationStatus: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "http://terminology.hl7.org/CodeSystem/condition-ver-status",
                code: @disease.diagnosed_by_hp? ? "confirmed" : "unconfirmed",
                display: @disease.diagnosed_by_hp? ? "Confirmed" : "Unconfirmed"
              )
            ]
          ),
          category: [
            FHIR::CodeableConcept.new(
              coding: [
                FHIR::Coding.new(
                  system: "http://terminology.hl7.org/CodeSystem/condition-category",
                  code: "problem-list-item",
                  display: "Problem List Item"
                )
              ]
            )
          ],
          severity: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "http://snomed.info/sct",
                code: severity_code,
                display: severity_display
              )
            ]
          ),
          code: FHIR::CodeableConcept.new(
            coding: build_code_coding,
            text: @disease.predefined_disease.name
          ),
          subject: reference_to_patient,
          onsetDateTime: @disease.diagnosed_at&.iso8601,
          note: build_note
        )
      end

      def to_fhir_json
        to_fhir&.to_json
      end

      private

      def clinical_status_code
        case @disease.status
        when "cured" then "resolved"
        else "active"
        end
      end

      def severity_code
        case @disease.severity
        when 1 then "255604002" # Mild
        when 2 then "6736007" # Moderate
        when 3..5 then "24484000" # Severe
        # rubocop:disable Lint/DuplicateBranch
        else "6736007" # Moderate (default)
          # rubocop:enable Lint/DuplicateBranch
        end
      end

      def severity_display
        case @disease.severity
        when 1 then "Mild"
        when 2 then "Moderate"
        else "Severe"
        end
      end

      def reference_to_patient
        return nil unless @disease.account_id

        FHIR::Reference.new(
          reference: "Patient/#{@disease.account_id}"
        )
      end

      def build_code_coding
        codes = []

        if snomed_code
          codes << FHIR::Coding.new(
            system: "http://snomed.info/sct",
            code: snomed_code,
            display: @disease.predefined_disease.name
          )
        end

        if icd10_code
          codes << FHIR::Coding.new(
            system: "http://hl7.org/fhir/sid/icd-10",
            code: icd10_code,
            display: @disease.predefined_disease.name
          )
        end

        if @disease.predefined_disease.icd10_code.present?
          codes << FHIR::Coding.new(
            system: "http://fhir.de/CodeSystem/icd-10",
            code: @disease.predefined_disease.icd10_code,
            display: @disease.predefined_disease.name
          )
        end

        codes.presence || [
          FHIR::Coding.new(
            system: "http://example.org",
            code: @disease.predefined_disease.id.to_s,
            display: @disease.predefined_disease.name
          )
        ]
      end

      def snomed_code
        @snomed_code ||= Fhir::Codes::Icd10Codes.for(@disease.predefined_disease.name)&.dig(:code)
      end

      def icd10_code
        @disease.predefined_disease.icd10_code.presence ||
          Fhir::Codes::Icd10Codes.for(@disease.predefined_disease.name)&.dig(:code)
      end

      def build_note
        return nil if @disease.predefined_disease.description.blank?

        [FHIR::Annotation.new(text: @disease.predefined_disease.description)]
      end
    end
  end
end
