class CreateSpecialistReferralClicks < ActiveRecord::Migration[7.1]
  def change
    create_table :specialist_referral_clicks, id: :uuid do |t|
      t.references :specialist_request, type: :uuid, null: false, foreign_key: true
      t.datetime :clicked_at, null: false
      t.string :ip_address, limit: 45
      t.string :user_agent, limit: 512

      t.index %i[specialist_request_id clicked_at]
    end
  end
end
