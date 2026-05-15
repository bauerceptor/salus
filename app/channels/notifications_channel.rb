class NotificationsChannel < ApplicationCable::Channel
  def subscribed
    account = Account.find(params[:account_id])
    stream_for account
  end

  def unsubscribed
    stop_stream_from_all
  end
end
