class Admin::DashboardController < Admin::BaseController
  def index
    @stats = {
      total_patients: Account.count,
      assigned: SpecialistPatient.active.count,
      unassigned: Account.count - SpecialistPatient.active.count,
      pending_requests: SpecialistRequest.where(status: "pending").count,
      active_specialists: User.joins(:roles).where(roles: { name: "specialist" }).count
    }

    @trends = {
      patients_30d: Account.where("created_at > ?", 30.days.ago).count,
      messages_30d: ChatroomMessage.where("created_at > ?", 30.days.ago).count,
      active_today: ChatroomMessage.where("created_at > ?", 24.hours.ago).distinct.count(:account_id)
    }
  end
end
