class Auth::SessionsController < ApplicationController
  before_action :redirect_if_authenticated, only: %i[new create]

  def new; end

  def create
    user = User.find_by(email: params.dig(:session, :email))

    if user&.authenticate(params.dig(:session, :password))
      log_in user
      if user.specialist?
        redirect_to specialist_dashboard_path, notice: t(".notice")
      else
        redirect_to authenticated_root_path, notice: t(".notice")
      end
    else
      flash.now[:alert] = t(".alert")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    log_out
    redirect_to root_path, notice: t(".notice")
  end

  private

  def redirect_if_authenticated
    return unless user_signed_in?

    redirect_to authenticated_root_path
  end
end
