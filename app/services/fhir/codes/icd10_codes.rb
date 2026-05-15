# frozen_string_literal: true

module Fhir
  module Codes
    class Icd10Codes
      ICD10_CODES = {
        "atopic_dermatitis" => { code: "L20", display: "Atopic dermatitis" },
        "multiple_sclerosis" => { code: "G35", display: "Multiple sclerosis" },
        "overweight" => { code: "R63.5", display: "Overweight" },
        "diabetes" => { code: "E11", display: "Type 2 diabetes mellitus" },
        "heart_failure" => { code: "I50", display: "Heart failure" },
        "osteoporosis" => { code: "M81", display: "Osteoporosis" },
        "hypertension" => { code: "I10", display: "Essential (primary) hypertension" },
        "hypothyroidism" => { code: "E03.9", display: "Hypothyroidism, unspecified" },
        "asthma" => { code: "J45", display: "Asthma" },
        "celiac_disease" => { code: "K90.0", display: "Celiac disease" },
        "psoriasis" => { code: "L40", display: "Psoriasis" },
        "crohn_disease" => { code: "K50", display: "Crohn's disease" },
        "parkinson_disease" => { code: "G20", display: "Parkinson's disease" },
        "endometriosis" => { code: "N80", display: "Endometriosis" }
      }.freeze

      def self.for(disease_name)
        key = disease_name.to_s.downcase.tr(" ", "_").to_sym
        ICD10_CODES[key]
      end

      def self.all
        ICD10_CODES
      end
    end
  end
end
