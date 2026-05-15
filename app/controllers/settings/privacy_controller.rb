class Settings::PrivacyController < BaseController
  before_action :set_account
  before_action :set_breadcrumbs

  def show
    @privacy_settings = current_account.privacy_settings
  end

  def update
    if current_account.update_privacy_settings(privacy_params)
      redirect_to settings_privacy_path, notice: t(".success")
    else
      @privacy_settings = current_account.privacy_settings
      render :show, status: :unprocessable_content
    end
  end

  private

  def privacy_params
    params.fetch(:privacy, {}).permit(
      :profile_visibility,
      :show_health_data,
      :allow_friend_requests,
      :show_online_status,
      :share_measurements
    )
  end

  def set_account
    @account = current_account
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), authenticated_root_path
    add_breadcrumb t("settings.breadcrumbs.index"), settings_settings_path
    add_breadcrumb t(".breadcrumbs.show"), settings_privacy_path
  end
end
