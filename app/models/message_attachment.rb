class MessageAttachment < ApplicationRecord
  belongs_to :message, class_name: "SpecialistMessage"

  TYPES = %w[image video audio document voice].freeze

  validates :file_type, inclusion: { in: TYPES }

  def url
    return nil if file_data.blank?
    "data:#{content_type};base64,#{file_data}"
  end

  def image?
    file_type == "image"
  end

  def video?
    file_type == "video"
  end

  def audio?
    %w[audio voice].include?(file_type)
  end

  def document?
    file_type == "document"
  end
end
