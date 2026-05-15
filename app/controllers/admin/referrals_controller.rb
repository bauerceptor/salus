class Admin::ReferralsController < Admin::BaseController
  def index
    @referrals_data = SpecialistRequest.connection.execute(specialist_referrals_sql).to_a
  end

  private

  def specialist_referrals_sql
    <<~SQL.squish
      SELECT
        sr.id,
        sr.hash_code,
        sr.status,
        u.email AS specialist_email,
        sp_specialization.specialization,
        COUNT(src.id) AS click_count,
        COUNT(sp.id) AS conversion_count
      FROM specialist_requests sr
      INNER JOIN users u ON u.id = sr.specialist_id
      LEFT OUTER JOIN specialists sp_specialization ON sp_specialization.user_id = u.id
      LEFT OUTER JOIN specialist_referral_clicks src ON src.specialist_request_id = sr.id
        AND src.clicked_at >= NOW() - INTERVAL '30 days'
      LEFT OUTER JOIN specialist_patients sp ON sp.specialist_id = sr.specialist_id
        AND sp.created_at >= sr.created_at
      WHERE sr.status = 'approved'
      GROUP BY sr.id, u.email, sp_specialization.specialization
      ORDER BY COUNT(src.id) DESC
    SQL
  end
end
