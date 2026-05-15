import consumer from "./consumer"

let presenceSubscription = null

function setupPresenceSubscription() {
  if (presenceSubscription) return

  presenceSubscription = consumer.subscriptions.create(
    { channel: "PresenceChannel" },
    {
      received(data) {
        if (data.type === "presence") {
          updateUserPresence(data)
        } else if (data.type === "typing") {
          showTypingIndicator(data)
        }
      }
    }
  )
}

function updateUserPresence(data) {
  const userElement = document.querySelector(`[data-account-id="${data.account_id}"]`)
  if (userElement) {
    const statusDot = userElement.querySelector('.online-status-dot')
    if (statusDot) {
      if (data.online_status === 'online') {
        statusDot.classList.remove('hidden')
        statusDot.classList.add('bg-green-500')
      } else if (data.online_status === 'offline') {
        statusDot.classList.add('hidden')
        statusDot.classList.remove('bg-green-500')
      }
    }
  }
}

function showTypingIndicator(data) {
  const typingElement = document.getElementById('typing-indicator')
  if (typingElement) {
    typingElement.textContent = `${data.username} is typing...`
    typingElement.classList.remove('hidden')

    clearTimeout(window.typingTimeout)
    window.typingTimeout = setTimeout(() => {
      typingElement.classList.add('hidden')
    }, 3000)
  }
}

function stopPresenceSubscription() {
  if (presenceSubscription) {
    presenceSubscription.unsubscribe()
    presenceSubscription = null
  }
}

document.addEventListener("turbo:load", setupPresenceSubscription)
document.addEventListener("turbo:before-visit", stopPresenceSubscription)