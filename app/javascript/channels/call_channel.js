import consumer from "./consumer"

let callSubscription = null
let callManager = null

function setupCallSubscription() {
  if (callSubscription) return

  callSubscription = consumer.subscriptions.create(
    { channel: "CallChannel" },
    {
      received(data) {
        handleCallEvent(data)
      }
    }
  )
}

function handleCallEvent(data) {
  switch (data.type) {
    case 'incoming_call':
      showIncomingCallModal(data)
      break
    case 'call_accepted':
      handleCallAccepted(data)
      break
    case 'call_rejected':
      handleCallRejected(data)
      break
    case 'call_ended':
      handleCallEnded(data)
      break
    case 'offer':
      handleOffer(data)
      break
    case 'answer':
      handleAnswer(data)
      break
    case 'ice_candidate':
      handleIceCandidate(data)
      break
  }
}

function showIncomingCallModal(data) {
  const modal = document.getElementById('call-modal')
  if (modal) {
    modal.classList.remove('hidden')
    const callerName = modal.querySelector('.caller-name')
    if (callerName) callerName.textContent = data.caller_name

    if (callManager) {
      callManager.onIncomingCall(data)
    }
  }
}

function handleCallAccepted(data) {
  const modal = document.getElementById('call-modal')
  if (modal) {
    modal.querySelector('.call-status').textContent = 'Connected'
  }
}

function handleCallRejected(data) {
  const modal = document.getElementById('call-modal')
  if (modal) {
    modal.classList.add('hidden')
  }
}

function handleCallEnded(data) {
  const modal = document.getElementById('call-modal')
  if (modal) {
    modal.classList.add('hidden')
  }
  if (callManager) {
    callManager.endCall()
  }
}

function handleOffer(data) {
  if (callManager) {
    callManager.onOffer(data)
  }
}

function handleAnswer(data) {
  if (callManager) {
    callManager.onAnswer(data)
  }
}

function handleIceCandidate(data) {
  if (callManager) {
    callManager.onIceCandidate(data)
  }
}

function stopCallSubscription() {
  if (callSubscription) {
    callSubscription.unsubscribe()
    callSubscription = null
  }
}

document.addEventListener("turbo:load", setupCallSubscription)
document.addEventListener("turbo:before-visit", stopCallSubscription)

window.CallChannel = {
  startCall: function(chatroomId, recipientId, callType) {
    if (callSubscription) {
      callSubscription.send({
        action: 'start_call',
        data: {
          chatroom_id: chatroomId,
          recipient_id: recipientId,
          call_type: callType
        }
      })
    }
  },
  endCall: function(recipientId) {
    if (callSubscription) {
      callSubscription.send({
        action: 'end_call',
        data: { recipient_id: recipientId }
      })
    }
  },
  acceptCall: function(recipientId) {
    if (callSubscription) {
      callSubscription.send({
        action: 'accept_call',
        data: { recipient_id: recipientId }
      })
    }
  },
  rejectCall: function(recipientId) {
    if (callSubscription) {
      callSubscription.send({
        action: 'reject_call',
        data: { recipient_id: recipientId }
      })
    }
  },
  sendOffer: function(recipientId, sdp) {
    if (callSubscription) {
      callSubscription.send({
        action: 'send_offer',
        data: { recipient_id: recipientId, sdp: sdp }
      })
    }
  },
  sendAnswer: function(recipientId, sdp) {
    if (callSubscription) {
      callSubscription.send({
        action: 'send_answer',
        data: { recipient_id: recipientId, sdp: sdp }
      })
    }
  },
  sendIceCandidate: function(recipientId, candidate) {
    if (callSubscription) {
      callSubscription.send({
        action: 'send_ice_candidate',
        data: { recipient_id: recipientId, candidate: candidate }
      })
    }
  }
}