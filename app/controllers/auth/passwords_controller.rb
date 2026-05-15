class Auth::PasswordsController < ApplicationController
  def new; end

  def edit
    @user = User.find_by(reset_password_token: params[:token])
    redirect_to new_password_path unless @user&.reset_password_token_valid?
  end

  def create
    user = User.find_by(email: params[:email])

    if user.present?
      user.generate_reset_password_token!
      UserMailer.with(user: user).reset_password.deliver_later
    end

    redirect_to new_session_path, notice: t(".notice")
  end

  def update
    @user = User.find_by(reset_password_token: params[:token])

    if @user&.reset_password_token_valid? && @user.update(reset_password_params)
      @user.clear_reset_password_token!
      log_in @user
      redirect_to authenticated_root_path, notice: t(".notice")
    else
      redirect_to new_password_path, alert: t(".alert")
    end
  end

  private

  def reset_password_params
    params.expect(user: %i[password password_confirmation])
  end
end
