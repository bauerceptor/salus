class Specialist::Notifications::AcknowledgmentsController < Specialist::BaseController
  def create
    notification = current_user.specialist_notifications.find(params[:notification_id])
    notification.acknowledge!(specialist: current_user)

    notification.update!(acknowledgment_note: params[:note]) if params[:note].present?

    redirect_to specialist_notifications_path, notice: "Alert resolved."
  rescue ActiveRecord::RecordNotFound
    redirect_to specialist_notifications_path, alert: "Notification not found."
  end
end
