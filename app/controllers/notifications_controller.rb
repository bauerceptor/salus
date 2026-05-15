class NotificationsController < BaseController
  before_action :set_notification, only: %i[show update destroy]

  def index
    @pagy, @notifications = pagy(
      current_account.notifications.recent,
      items: 20
    )
  end

  def show
    @notification.mark_as_read
    render json: @notification
  end

  def update
    @notification.mark_as_read

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: t(".success") }
      format.json { render json: @notification }
    end
  end

  def destroy
    @notification.destroy

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: t(".success") }
      format.json { head :no_content }
    end
  end

  def mark_all_read
    current_account.notifications.unread.update_all(read_at: Time.current)

    respond_to do |format|
      format.html { redirect_to notifications_path, notice: t(".mark_all_read.success") }
      format.json { head :no_content }
    end
  end

  private

  def set_notification
    @notification = current_account.notifications.find(params[:id])
  end
end
