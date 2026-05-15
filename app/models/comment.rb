# == Schema Information
#
# Table name: comments
#
#  id               :uuid             not null, primary key
#  body             :text             default(""), not null
#  commentable_type :string           not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  account_id       :uuid             not null
#  commentable_id   :uuid             not null
#
# Indexes
#
#  index_comments_on_account_id   (account_id)
#  index_comments_on_commentable  (commentable_type,commentable_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#
class Comment < ApplicationRecord
  belongs_to :commentable, polymorphic: true
  belongs_to :account

  validates :body, presence: true, length: { maximum: 500 }

  scope :expert_pinned, -> { where.not(expert_pinned_at: nil).order(expert_pinned_at: :desc) }
  scope :ordered, -> { order(created_at: :asc) }

  def expert_pinned?
    expert_pinned_at.present?
  end

  def pin_as_expert!(commenter)
    return false unless commenter.user&.specialist?
    return false unless commenter.user.specialist_patients.active.any?

    update!(expert_pinned_at: Time.current)
  end

  def unpin_as_expert!
    update!(expert_pinned_at: nil) if expert_pinned_at.present?
  end
end
