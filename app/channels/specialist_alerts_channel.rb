class SpecialistAlertsChannel < ApplicationCable::Channel
  def subscribed
    specialist = User.find(params[:specialist_id])
    stream_for specialist
  end

  def unsubscribed
    stop_stream_from_all
  end
end
