class Public::JoinController < ApplicationController
  before_action :load_specialist_request, only: [:specialist]

  def specialist
    if @specialist_request.nil?
      render file: "#{Rails.root}/public/404.html", status: :not_found
      return
    end

    @click = SpecialistReferralClick.create!(
      specialist_request: @specialist_request,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      clicked_at: Time.current
    )
  end

  def create
    @specialist_request = SpecialistRequest.find_by(hash_code: params[:hash])
    if @specialist_request.nil?
      render file: "#{Rails.root}/public/404.html", status: :not_found
      return
    end

    unless user_signed_in? && current_account.present?
      redirect_to auth_new_session_path(locale: I18n.locale)
      return
    end

    existing = SpecialistPatient.active.exists?(
      account: current_account,
      specialist: @specialist_request.specialist
    )

    if existing
      redirect_to join_specialist_path(hash: params[:hash]), alert: "You are already associated with this specialist."
      return
    end

    SpecialistPatient.create!(
      account: current_account,
      specialist: @specialist_request.specialist,
      relationship_type: "primary_care",
      status: "pending"
    )

    redirect_to join_specialist_path(hash: params[:hash]), notice: "Request sent successfully."
  end

  private

  def load_specialist_request
    @specialist_request = SpecialistRequest.find_by(hash_code: params[:hash])
    return unless @specialist_request.nil? || @specialist_request.status == "rejected"

    @specialist_request = nil
  end
end
