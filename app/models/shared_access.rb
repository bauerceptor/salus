class SharedAccess < ApplicationRecord
  belongs_to :account, optional: false
  belongs_to :shared_with_account, class_name: "Account", optional: false
  belongs_to :shareable, polymorphic: true, optional: true

  validates :account_id, presence: true
  validates :shared_with_account_id, presence: true

  scope :active, -> { where("expires_at IS NULL OR expires_at > ?", Time.current) }
  scope :for_shared_with, ->(account) { where(shared_with_account_id: account.id) }
  scope :for_shareable, ->(type, id) { where(shareable_type: type, shareable_id: id) }

  PERMISSION_LEVELS = {
    view_only: 0,
    view_and_comment: 1,
    edit: 2,
    full_access: 3
  }.freeze

  def active?
    expires_at.nil? || expires_at > Time.current
  end

  def expired?
    !active?
  end

  def can_view?
    true
  end

  def can_edit?
    permission_level >= PERMISSION_LEVELS[:edit]
  end

  def can_full_access?
    permission_level >= PERMISSION_LEVELS[:full_access]
  end
end
