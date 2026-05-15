# frozen_string_literal: true

module Fhir
  module Export
    class PatientExporter
      def initialize(account)
        @account = account
      end

      def to_fhir
        return nil if @account.blank?

        FHIR::Patient.new(
          id: @account.id,
          identifier: build_identifier,
          active: !@account.is_hidden,
          name: build_name,
          telecom: build_telecom,
          gender: map_gender,
          birthDate: @account.birthday&.iso8601,
          address: build_address,
          communication: build_communication,
          generalPractitioner: build_general_practitioner
        )
      end

      def to_fhir_json
        to_fhir&.to_json
      end

      private

      def build_identifier
        [
          FHIR::Identifier.new(
            use: "official",
            system: "http://salus.local/patient",
            value: @account.username
          )
        ]
      end

      def build_name
        [
          FHIR::HumanName.new(
            use: "official",
            family: @account.last_name.to_s,
            given: [@account.first_name].compact
          )
        ]
      end

      def build_telecom
        telecom = []

        if @account.phone_number.present?
          telecom << FHIR::ContactPoint.new(
            system: "phone",
            value: @account.phone_number,
            use: "mobile"
          )
        end

        if @account.user&.email.present?
          telecom << FHIR::ContactPoint.new(
            system: "email",
            value: @account.user.email,
            use: "home"
          )
        end

        telecom
      end

      def map_gender
        case @account.sex
        when "male" then "male"
        when "female" then "female"
        else "unknown"
        end
      end

      def build_address
        return nil unless address?

        FHIR::Address.new(
          use: "home",
          city: @account.city,
          country: @account.country
        )
      end

      def address?
        @account.city.present? || @account.country.present?
      end

      def build_communication
        [FHIR::Patient::Communication.new(
          language: FHIR::CodeableConcept.new(
            coding: [
              FHIR::Coding.new(
                system: "urn:ietf:bcp:47",
                code: "en",
                display: "English"
              )
            ]
          ),
          preferred: true
        )]
      end

      def build_general_practitioner
        primary_sps = @account.specialist_patients.active.where(relationship_type: "primary_care")
        return nil if primary_sps.empty?

        primary_sps.map do |sp|
          FHIR::Reference.new(
            reference: "Practitioner/#{sp.specialist_id}"
          )
        end
      end
    end
  end
end
