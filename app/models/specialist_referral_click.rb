class SpecialistReferralClick < ApplicationRecord
  belongs_to :specialist_request

  before_validation :set_clicked_at, on: :create

  delegate :hash_code, to: :specialist_request

  private

  def set_clicked_at
    self.clicked_at ||= Time.current
  end
end
