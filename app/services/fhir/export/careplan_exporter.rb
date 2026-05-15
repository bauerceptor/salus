# frozen_string_literal: true

module Fhir
  module Export
    class CarePlanExporter
      def initialize(treatment)
        @treatment = treatment
      end

      def to_fhir
        return nil if @treatment.blank?

        FHIR::CarePlan.new(
          id: @treatment.id,
          status: careplan_status,
          intent: "plan",
          title: @treatment.title,
          description: @treatment.description,
          subject: reference_to_patient,
          period: period,
          authoredOn: @treatment.start_date&.iso8601,
          careTeam: build_care_team,
          addresses: build_addresses,
          note: build_note
        )
      end

      def to_fhir_json
        to_fhir&.to_json
      end

      private

      def reference_to_patient
        return nil unless @treatment.account_id

        FHIR::Reference.new(
          reference: "Patient/#{@treatment.account_id}"
        )
      end

      def careplan_status
        case @treatment.is_finished
        when true then "completed"
        when false then "active"
        else "active"
        end
      end

      def period
        FHIR::Period.new(
          start: @treatment.start_date&.iso8601,
          end: @treatment.end_date&.iso8601
        )
      end

      def build_care_team
        @treatment.diseases.map do |disease|
          FHIR::Reference.new(
            reference: "Condition/#{disease.id}"
          )
        end
      end

      def build_addresses
        @treatment.diseases.map do |disease|
          FHIR::Reference.new(
            reference: "Condition/#{disease.id}",
            display: disease.predefined_disease.name
          )
        end
      end

      def build_note
        notes = []

        notes << "Effectiveness: #{effectiveness_text}" if @treatment.effectiveness.present?
        notes << "Duration: #{@treatment.days_difference} days" if @treatment.days_difference.present?

        return nil if notes.empty?

        [FHIR::Annotation.new(text: notes.join(". "))]
      end

      def effectiveness_text
        case @treatment.effectiveness
        when 1 then "Very Poor"
        when 2 then "Poor"
        when 3 then "Fair"
        when 4 then "Good"
        when 5 then "Excellent"
        else "Unknown"
        end
      end
    end
  end
end
