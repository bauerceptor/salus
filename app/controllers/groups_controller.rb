class GroupsController < BaseController
  before_action :set_group, only: %i[show join_group leave_group]
  before_action :set_breadcrumbs

  def index
    @pagy_account, @account_groups = pagy(
      current_account.groups.joins(:predefined_disease)
    )

    non_member_ids = current_account.groups.pluck(:id)
    @pagy_available, @available_groups = pagy(
      Group
      .where.not(id: non_member_ids)
      .or(Group.where(predefined_disease: { special: true }))
      .joins(:predefined_disease)
      .includes(:predefined_disease)
      .where(predefined_disease: { special: false })
    )

    @special_groups = Group.joins(:predefined_disease).where(predefined_disease: { special: true })

    @available_groups_ids = @available_groups.map(&:id) + @special_groups.map(&:id)
  end

  def join_group
    return redirect_to_group if @group.special?

    @group.accounts << current_account

    respond_to do |format|
      format.html { redirect_to groups_path, notice: t(".success") }
    end
  end

  def leave_group
    return redirect_to_group if @group.special?

    @group.accounts.delete(current_account)

    respond_to do |format|
      format.html { redirect_to groups_path, notice: t(".success") }
    end
  end

  private

  def set_group
    @group = Group.find(params[:id])
  end

  def redirect_to_group
    respond_to do |format|
      format.html { redirect_to @group, notice: t(".special_group") }
    end
  end

  def set_breadcrumbs
    add_breadcrumb t("breadcrumbs.home"), authenticated_root_path
    add_breadcrumb t(".breadcrumbs.index"), groups_path

    case action_name.to_sym
    when :show
      add_breadcrumb @group.predefined_disease.name.titleize, @group
    end
  end
end
