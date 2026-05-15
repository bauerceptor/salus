class ClinicalDocumentProcessingJob < ApplicationJob
  queue_as :default

  def perform(document_id)
    document = ClinicalDocument.find(document_id)

    document.update!(ai_processed: true)
  rescue ActiveRecord::RecordNotFound
    nil
  end
end