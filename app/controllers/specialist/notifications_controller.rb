class Specialist::NotificationsController < Specialist::BaseController
  def index
    @critical = current_user.specialist_notifications.critical.unacknowledged.order(created_at: :desc)
    @warning  = current_user.specialist_notifications.warning.unacknowledged.order(created_at: :desc)
    @info     = current_user.specialist_notifications.info.unacknowledged.order(created_at: :desc)
    @total_unacknowledged = current_user.specialist_notifications.unacknowledged.count
  end
end
