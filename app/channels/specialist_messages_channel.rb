class SpecialistMessagesChannel < ApplicationCable::Channel
  def subscribed
    if params[:account_id]
      account = Account.find(params[:account_id])
      stream_for account
    elsif params[:specialist_id]
      specialist = User.find(params[:specialist_id])
      stream_for specialist
    end
  end

  def unsubscribed
    stop_stream_from_all
  end
end
