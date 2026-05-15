# frozen_string_literal: true

class Admin::SessionsController < Admin::BaseController
  skip_before_action :authenticate_admin!, only: %i[new create]
  before_action :redirect_if_authenticated, only: %i[new create]
  layout "application", only: %i[new create]

  def new; end

  def create
    admin = AdminUser.find_by(email: params[:admin][:email])

    if admin&.authenticate(params[:admin][:password])
      session[:admin_id] = admin.id
      redirect_to admin_dashboard_path, notice: t(".notice")
    else
      flash.now[:alert] = t(".alert")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    session.delete(:admin_id)
    redirect_to admin_new_session_path, notice: t(".notice")
  end

  private

  def redirect_if_authenticated
    return if current_admin.blank?

    redirect_to admin_dashboard_path
  end
end
