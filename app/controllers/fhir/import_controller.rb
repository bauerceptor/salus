# frozen_string_literal: true

module Fhir
  class ImportController < BaseController
    before_action :authenticate_user!

    def new
      @import_result = nil
    end

    def create
      if params[:file].blank?
        flash[:error] = "Please select a FHIR JSON file to import"
        redirect_to fhir_import_new_path and return
      end

      begin
        @import_result = Fhir::Import::BundleImporter.from_json(
          params[:file].read,
          current_account.id
        ).import_all

        if @import_result[:errors].any?
          flash[:warning] = "Import completed with #{@import_result[:errors].count} errors"
        else
          flash[:success] = "Successfully imported #{import_summary}"
        end
      rescue Fhir::ImportError => e
        flash[:error] = "Import failed: #{e.message}"
      rescue StandardError => e
        flash[:error] = "Import failed: #{e.message}"
      end

      redirect_to fhir_import_new_path
    end

    def import_document
      if params[:file].blank?
        flash[:error] = "Please select a PDF file to import"
        redirect_to fhir_import_new_path and return
      end

      file = params[:file]
      unless file.content_type == "application/pdf" || file.content_type.to_s.include?("pdf")
        flash[:error] = "Only PDF files are supported"
        redirect_to fhir_import_new_path and return
      end

      document_type = params[:document_type].presence || "other"

      unless ClinicalDocument::DOCUMENT_TYPES.include?(document_type)
        flash[:error] = "Invalid document type"
        redirect_to fhir_import_new_path and return
      end

      begin
        pdf_data = file.read
        Rails.logger.debug "PDF data size: #{pdf_data.size} bytes"

        fhir_doc = build_fhir_document_reference(pdf_data, file.original_filename, document_type)
        Rails.logger.debug "FHIR doc built, content present: #{fhir_doc.content.first.attachment.data.present?}"

        importer = Fhir::Import::DocumentReferenceImporter.new(
          fhir_doc,
          current_account.id,
          current_user.id
        )

        Rails.logger.debug "Importer valid?: #{importer.send(:valid?)}"
        Rails.logger.debug "Importer content: #{importer.send(:content).inspect}"

        document = importer.to_local

        if document
          flash[:success] = "Document imported successfully"
        else
          Rails.logger.error "Import failed - importer returned nil"
          flash[:error] = "Failed to import document"
        end
      rescue StandardError => e
        Rails.logger.error "Document import error: #{e.message}\n#{e.backtrace.first(10).join("\n")}"
        flash[:error] = "Import failed: #{e.message}"
      end

      redirect_to fhir_import_new_path
    end

    private

    def import_summary
      parts = []
      parts << "#{@import_result[:observations].count} measurements" if @import_result[:observations].any?
      parts << "#{@import_result[:conditions].count} diseases" if @import_result[:conditions].any?
      parts << "#{@import_result[:medications].count} medications" if @import_result[:medications].any?
      parts << "#{@import_result[:documents].count} documents" if @import_result[:documents].any?
      parts.join(", ")
    end

    def build_fhir_document_reference(pdf_data, filename, document_type)
      require "base64"

      doc_type_mapping = {
        "lab_result" => { system: "http://loinc.org", code: "34746-6", display: "Laboratory Result" },
        "imaging_report" => { system: "http://loinc.org", code: "34117-2", display: "Imaging Report" },
        "clinical_note" => { system: "http://loinc.org", code: "34122-2", display: "Clinical Note" },
        "discharge_summary" => { system: "http://loinc.org", code: "28654-3", display: "Discharge Summary" },
        "other" => { system: "http://loinc.org", code: "_other", display: "Other Document" }
      }

      type_info = doc_type_mapping[document_type] || doc_type_mapping["other"]

      OpenStruct.new(
        resourceType: "DocumentReference",
        id: SecureRandom.uuid,
        type: OpenStruct.new(
          coding: [
            OpenStruct.new(
              system: type_info[:system],
              code: type_info[:code],
              display: type_info[:display]
            )
          ],
          text: document_type.humanize
        ),
        content: [
          OpenStruct.new(
            attachment: OpenStruct.new(
              contentType: "application/pdf",
              title: filename,
              data: Base64.strict_encode64(pdf_data)
            )
          )
        ]
      )
    end
  end
end
