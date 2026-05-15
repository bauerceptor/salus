class MedicationLog < ApplicationRecord
  belongs_to :medication
  belongs_to :account
  belongs_to :medication_schedule, optional: true

  enum :status, { pending: "pending", taken: "taken", skipped: "skipped", missed: "missed", delayed: "delayed" }

  validates :status, presence: true

  scope :for_account, ->(account) { where(account_id: account.id) }
  scope :recent, -> { where(scheduled_for: 30.days.ago..) }
  scope :for_date, lambda { |date|
    where(scheduled_for: date.beginning_of_day...date.end_of_day)
  }

  def mark_as_taken(notes: nil)
    update!(status: :taken, taken_at: Time.current, notes: notes)
  end

  def mark_as_skipped(notes: nil)
    update!(status: :skipped, notes: notes)
  end

  def mark_as_missed
    update!(status: :missed) if pending? && scheduled_for < Time.current
  end
end
