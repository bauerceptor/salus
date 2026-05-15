# frozen_string_literal: true

module Fhir
  module Import
    class ObservationImporter
      def initialize(fhir_observation, account_id)
        @fhir = fhir_observation
        @account_id = account_id
      end

      def to_local
        return nil unless valid?

        measurement_type = find_or_create_measurement_type
        return nil unless measurement_type

        value = extract_value

        Measurement.create_or_find_by!(
          id: @fhir.id,
          account_id: @account_id,
          measurement_type_id: measurement_type.id,
          value: value,
          measurement_date: effective_date,
          is_within_limits: within_limits?(value, measurement_type)
        )
      end

      private

      def valid?
        @fhir.resource présent && @fhir.code.present?
      end

      def effective_date
        @fhir.effectiveDateTime || Time.current
      end

      def extract_value
        if @fhir.valueQuantity.present?
          "#{@fhir.valueQuantity.value}#{@fhir.valueQuantity.unit || ''}"
        elsif @fhir.valueString.present?
          @fhir.valueString
        end
      end

      def find_or_create_measurement_type
        loinc_code = @fhir.code.coding.find { |c| c.system == "http://loinc.org" }
        return nil unless loinc_code

        type_name = loinc_to_type_name(loinc_code.code)
        return nil unless type_name

        MeasurementType.find_or_create_by!(name: type_name) do |mt|
          mt.unit = find_or_create_unit(loinc_code)
        end
      end

      def loinc_to_type_name(code)
        case code
        when "29463-7" then "weight"
        when "8867-4" then "heart_beat"
        when "8480-6", "8462-4", "85354-9" then "blood_pressure"
        when "2339-0" then "sugar"
        when "2708-6" then "spo2"
        end
      end

      def find_or_create_unit(loinc_code)
        unit_symbol = @fhir.valueQuantity&.unit || default_unit_for_code(loinc_code.code)
        return nil unless unit_symbol

        Unit.find_or_create_by!(symbol: unit_symbol) do |u|
          u.name = unit_symbol
        end
      end

      def default_unit_for_code(code)
        case code
        when "29463-7" then "kg"
        when "8867-4" then "/min"
        when "8480-6", "8462-4" then "mmHg"
        when "2339-0" then "mg/dL"
        when "2708-6" then "%"
        end
      end

      def within_limits?(value, measurement_type)
        return true unless measurement_type.lower_limit.present? && measurement_type.upper_limit.present?

        val = value.to_s.gsub(/[^\d.]/, "").to_f
        val.between?(measurement_type.lower_limit.to_f, measurement_type.upper_limit.to_f)
      end
    end
  end
end
