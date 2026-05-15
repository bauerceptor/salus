class Specialist::BaseController < ApplicationController
  before_action :ensure_specialist!
  layout "specialist_dashboard"

  private

  def ensure_specialist!
    if current_user.nil?
      redirect_to specialist_new_session_path, alert: "Please sign in to continue."
    elsif !current_user.specialist?
      redirect_to authenticated_root_path, alert: "Access denied. Specialists only."
    end
  end
end
