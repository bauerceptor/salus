# == Schema Information
#
# Table name: specialist_notes
#
#  id          :uuid             not null, primary key
#  account_id  :uuid             not null, primary key
#  content     :text             not null
#  note_type   :string           default("observation"), not null
#  specialist_id :uuid           not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_specialist_notes_on_specialist_id_and_account_id  (specialist_id,account_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (specialist_id => users.id)
#
class SpecialistNote < ApplicationRecord
  belongs_to :specialist, class_name: "User"
  belongs_to :account

  has_many :attachments, class_name: "SpecialistNoteAttachment", dependent: :destroy

  NOTE_TYPES = %w[observation recommendation warning general].freeze
  FILE_TYPES = %w[image video audio document].freeze

  validates :note_type, inclusion: { in: NOTE_TYPES }
  validates :content, presence: true, length: { maximum: 2000 }

  scope :for_patient, ->(account) { where(account_id: account.id) }
  scope :by_specialist, ->(specialist) { where(specialist_id: specialist.id) }

  def note_type_badge_color
    case note_type
    when "warning" then "red"
    when "recommendation" then "yellow"
    else "blue"
    end
  end
end
