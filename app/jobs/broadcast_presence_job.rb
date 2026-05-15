class BroadcastPresenceJob < ApplicationJob
  queue_as :default

  def perform(account)
    ActionCable.server.broadcast(
      "presence_channel",
      {
        type: "presence",
        account_id: account.id,
        username: account.username,
        online_status: account.online_status,
        last_seen_at: account.last_seen_at&.iso8601,
        avatar_url: account.image.attached? ? url_for(account.image) : nil
      }
    )
  end
end
