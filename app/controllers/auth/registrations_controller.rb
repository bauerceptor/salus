class Auth::RegistrationsController < ApplicationController
  before_action :redirect_if_authenticated

  def new
    @user = User.new
    @user.build_account
  end

  def create
    @user = User.new(user_params)

    if @user.save
      log_in @user
      redirect_to authenticated_root_path, notice: t(".notice")
    else
      render :new, status: :unprocessable_content
    end
  end

  private

  def user_params
    params.expect(
      user: [:email,
             :password,
             :password_confirmation,
             :tos_agreement,
             { account_attributes: %i[first_name last_name username birthday] }]
    )
  end

  def redirect_if_authenticated
    return unless user_signed_in?

    redirect_to authenticated_root_path
  end
end
