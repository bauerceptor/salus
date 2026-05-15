# frozen_string_literal: true

require "base64"

module Fhir
  module Import
    class DocumentReferenceImporter
      DOCUMENT_TYPE_MAPPING = {
        "http://loinc.org" => {
          "34746-6" => "lab_result",
          "34117-2" => "imaging_report",
          "34122-2" => "clinical_note",
          "28654-3" => "discharge_summary"
        },
        "http://snomed.info/sct" => {
          "371525004" => "clinical_note",
          "309054003" => "clinical_note"
        }
      }.freeze

      def initialize(fhir_document_reference, account_id, uploaded_by_id)
        @fhir = fhir_document_reference
        @account_id = account_id
        @uploaded_by_id = uploaded_by_id
      end

      def to_local
        return nil unless valid?
        return nil if document_content.nil? || document_content.empty?

        document_type = extract_document_type
        parsed_content = extract_text_from_pdf(document_content)

        ClinicalDocument.create!(
          id: @fhir.id,
          account_id: @account_id,
          uploaded_by_id: @uploaded_by_id,
          document_type: document_type,
          file_data: {
            "content" => Base64.strict_encode64(document_content),
            "content_type" => content_type,
            "filename" => filename,
            "imported_at" => Time.current.iso8601
          },
          parsed_content: parsed_content,
          ai_processed: false
        )
      end

      private

      def valid?
        @fhir.resourceType == "DocumentReference" && !content.nil?
      end

      def content
        @content ||= @fhir.content.first.attachment if @fhir.content.any?
      end

      def document_content
        return nil unless content
        return nil unless content.data

        decode_base64(content.data)
      rescue StandardError => e
        Rails.logger.error "Error decoding document: #{e.message}"
        nil
      end

      def content_type
        content&.contentType || "application/pdf"
      end

      def filename
        content&.title || "document_#{@fhir.id}.pdf"
      end

      def decode_base64(base64_string)
        Base64.decode64(base64_string)
      rescue StandardError
        nil
      end

      def fetch_external_content(url)
        response = Faraday.get(url)
        response.body if response.success?
      rescue StandardError
        nil
      end

      def extract_document_type
        type_coding = @fhir.type&.coding&.find do |c|
          DOCUMENT_TYPE_MAPPING.keys.include?(c.system)
        end

        if type_coding
          mapped_type = DOCUMENT_TYPE_MAPPING.dig(type_coding.system, type_coding.code)
          return mapped_type if mapped_type
        end

        @fhir.type&.text&.downcase&.then do |text|
          case text
          when /lab/i then "lab_result"
          when /imaging|x-ray|ct|mri/i then "imaging_report"
          when /clinical|note/i then "clinical_note"
          when /discharge/i then "discharge_summary"
          else "other"
          end
        end || "other"
      end

      def extract_text_from_pdf(pdf_data)
        return nil if pdf_data.nil?
        return nil unless pdf_data.start_with?("%PDF")

        reader = PDF::Reader.new(StringIO.new(pdf_data))
        text = ""
        reader.pages.each do |page|
          text += "#{page.text}\n"
        end
        text.presence
      rescue StandardError => e
        Rails.logger.warn "PDF extraction failed: #{e.message}"
        nil
      end
    end
  end
end
