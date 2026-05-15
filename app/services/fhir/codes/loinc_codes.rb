# frozen_string_literal: true

module Fhir
  module Codes
    class LoincCodes
      LOINC_CODES = {
        weight: {
          code: "29463-7",
          display: "Body weight",
          system: "http://loinc.org",
          unit: "kg"
        },
        heart_beat: {
          code: "8867-4",
          display: "Heart rate",
          system: "http://loinc.org",
          unit: "/min"
        },
        blood_pressure_systolic: {
          code: "8480-6",
          display: "Systolic blood pressure",
          system: "http://loinc.org",
          unit: "mmHg"
        },
        blood_pressure_diastolic: {
          code: "8462-4",
          display: "Diastolic blood pressure",
          system: "http://loinc.org",
          unit: "mmHg"
        },
        blood_pressure: {
          code: "85354-9",
          display: "Blood pressure panel",
          system: "http://loinc.org",
          unit: nil
        },
        sugar: {
          code: "2339-0",
          display: "Glucose",
          system: "http://loinc.org",
          unit: "mg/dL"
        },
        spo2: {
          code: "2708-6",
          display: "Oxygen saturation",
          system: "http://loinc.org",
          unit: "%"
        }
      }.freeze

      def self.for(type)
        LOINC_CODES[type.to_sym] || LOINC_CODES[type.to_s.tr("-", "_").to_sym]
      end

      def self.all
        LOINC_CODES
      end
    end
  end
end
