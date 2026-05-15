class CallChannel < ApplicationCable::Channel
  def subscribed
    @account = @connection.current_account
    stream_for @account
  end

  def start_call(data)
    recipient = Account.find(data["recipient_id"])
    caller = @account

    ActionCable.server.broadcast(
      "account_#{recipient.id}",
      {
        type: "incoming_call",
        caller_id: caller.id,
        caller_name: caller.username,
        caller_avatar: caller.image.attached? ? url_for(caller.image) : nil,
        chatroom_id: data["chatroom_id"],
        call_type: data["call_type"] || "audio"
      }
    )
  end

  def accept_call(data)
    recipient = Account.find(data["recipient_id"])
    ActionCable.server.broadcast(
      "account_#{recipient.id}",
      {
        type: "call_accepted",
        callee_id: @account.id,
        callee_name: @account.username
      }
    )
  end

  def reject_call(data)
    recipient = Account.find(data["recipient_id"])
    ActionCable.server.broadcast(
      "account_#{recipient.id}",
      {
        type: "call_rejected",
        callee_id: @account.id,
        callee_name: @account.username
      }
    )
  end

  def end_call(data)
    recipient_id = data["recipient_id"]
    return unless recipient_id

    ActionCable.server.broadcast(
      "account_#{recipient_id}",
      {
        type: "call_ended",
        ender_id: @account.id,
        ender_name: @account.username
      }
    )
  end

  def send_offer(data)
    recipient_id = data["recipient_id"]
    return unless recipient_id

    ActionCable.server.broadcast(
      "account_#{recipient_id}",
      {
        type: "offer",
        sdp: data["sdp"],
        caller_id: @account.id
      }
    )
  end

  def send_answer(data)
    recipient_id = data["recipient_id"]
    return unless recipient_id

    ActionCable.server.broadcast(
      "account_#{recipient_id}",
      {
        type: "answer",
        sdp: data["sdp"],
        callee_id: @account.id
      }
    )
  end

  def send_ice_candidate(data)
    recipient_id = data["recipient_id"]
    return unless recipient_id

    ActionCable.server.broadcast(
      "account_#{recipient_id}",
      {
        type: "ice_candidate",
        candidate: data["candidate"],
        sender_id: @account.id
      }
    )
  end

  def typing(data)
    recipient_id = data["recipient_id"]
    chatroom_id = data["chatroom_id"]

    return unless recipient_id && chatroom_id

    ActionCable.server.broadcast(
      "chatroom_#{chatroom_id}",
      {
        type: "typing",
        account_id: @account.id,
        username: @account.username
      }
    )
  end
end
