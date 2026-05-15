# frozen_string_literal: true

module Fhir
  module Codes
    class RxnormCodes
      RXNORM_CODES = {
        "aspirin" => { code: "1191", display: "Aspirin 325 MG" },
        "ibuprofen" => { code: "5640", display: "Ibuprofen 400 MG" },
        "acetaminophen" => { code: "161", display: "Acetaminophen 325 MG" },
        "paracetamol" => { code: "161", display: "Acetaminophen 325 MG" },
        "metformin" => { code: "861007", display: "Metformin 500 MG" },
        "lisinopril" => { code: "314076", display: "Lisinopril 10 MG" },
        "atorvastatin" => { code: "83367", display: "Atorvastatin 20 MG" },
        "amlodipine" => { code: "17767", display: "Amlodipine 5 MG" },
        "omeprazole" => { code: "7646", display: "Omeprazole 20 MG" },
        "levothyroxine" => { code: "2010", display: "Levothyroxine 50 MCG" },
        "gabapentin" => { code: "25480", display: "Gabapentin 300 MG" },
        "prednisone" => { code: "8640", display: "Prednisone 5 MG" },
        "albuterol" => { code: "435", display: "Albuterol 2 MG" },
        "losartan" => { code: "52175", display: "Losartan 50 MG" },
        "metoprolol" => { code: "6908", display: "Metoprolol 25 MG" }
      }.freeze

      def self.for(medication_name)
        key = medication_name.to_s.downcase.gsub(/[^a-z0-9]/, "").to_sym
        RXNORM_CODES[key]
      end

      def self.all
        RXNORM_CODES
      end
    end
  end
end
