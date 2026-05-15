class Specialist::SessionsController < ApplicationController
  include Auth::Current

  before_action :redirect_if_authenticated, only: %i[new create]

  def new
    @specialist = true
  end

  def create
    user = User.find_by(email: params.dig(:session, :email))

    if user&.authenticate(params.dig(:session, :password)) && user.specialist?
      log_in user
      redirect_to specialist_dashboard_path, notice: t(".notice")
    elsif user&.authenticate(params.dig(:session, :password)) && !user.specialist?
      flash.now[:alert] = "This account is not a specialist account."
      render :new, status: :unprocessable_content
    else
      flash.now[:alert] = t(".alert")
      render :new, status: :unprocessable_content
    end
  end

  def destroy
    log_out
    redirect_to "/specialist/sign_in", notice: t(".notice")
  end

  private

  def redirect_if_authenticated
    return unless current_user&.specialist?

    redirect_to specialist_dashboard_path
  end
end
