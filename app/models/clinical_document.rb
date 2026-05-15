class ClinicalDocument < ApplicationRecord
  belongs_to :account
  belongs_to :uploaded_by, class_name: "User"

  DOCUMENT_TYPES = %w[lab_result imaging_report clinical_note discharge_summary other].freeze

  validates :document_type, inclusion: { in: DOCUMENT_TYPES }

  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :by_type, ->(type) { where(document_type: type) }

  def processed_content
    return nil if file_data.blank?

    content = file_data["content"]
    return nil if content.blank?

    content
  end
end
