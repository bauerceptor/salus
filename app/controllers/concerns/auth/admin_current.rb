# frozen_string_literal: true

module Auth
  module AdminCurrent
    extend ActiveSupport::Concern

    included do
      helper_method :current_admin, :admin_signed_in?
    end

    private

    def current_admin
      return @current_admin if defined?(@current_admin)

      @current_admin = AdminUser.find_by(id: session[:admin_id])
    end

    def admin_signed_in?
      current_admin.present?
    end

    def authenticate_admin!
      redirect_to admin_new_session_path unless admin_signed_in?
    end
  end
end
