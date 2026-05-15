module HealthAgent
  class BaseController < ApplicationController
    before_action :ensure_specialist!
    before_action :user_account_setup

    private

    def user_account_setup
      return if current_account.present?

      redirect_to setup_account_path
    end

    def ensure_specialist!
      if current_user.nil?
        redirect_to specialist_new_session_path, alert: "Please sign in to continue."
      elsif !current_user.specialist?
        redirect_to authenticated_root_path, alert: "Access denied. Specialists only."
      end
    end
  end
end
