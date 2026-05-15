class Specialist::ProfilesController < Specialist::BaseController
  before_action :set_breadcrumbs

  def show
    @specialist = current_user.specialist
    @account = current_account
  end

  def edit
    @specialist = current_user.specialist
    @account = current_account
  end

  def update
    @specialist = current_user.specialist
    @account = current_account

    if specialist_params.empty?
      if @account.update(account_params)
        redirect_to specialist_profile_path, notice: t(".account_success")
      else
        render :edit, status: :unprocessable_content
      end
    elsif @specialist.update(specialist_params)
      redirect_to specialist_profile_path, notice: t(".specialist_success")
    else
      render :edit, status: :unprocessable_content
    end
  end

  private

  def specialist_params
    params.expect(specialist: %i[specialization specialization_description field_of_expertise])
  end

  def account_params
    params.expect(account: %i[first_name last_name phone date_of_birth address city country])
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), specialist_dashboard_path
    add_breadcrumb t(".breadcrumbs.profile"), specialist_profile_path
  end
end
