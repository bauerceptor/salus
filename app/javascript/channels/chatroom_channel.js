import consumer from "channels/consumer"

let subscription = null
let currentChatroomId = null

function setupChatroomSubscription() {
  const messagesContainer = document.getElementById("messages-container")

  if (!messagesContainer) return

  const chatroomId = messagesContainer.dataset.chatroomId
  const currentAccountId = messagesContainer.dataset.currentAccountId

  if (subscription && currentChatroomId === chatroomId) {
    return
  }

  if (subscription) {
    subscription.unsubscribe()
    subscription = null
  }

  currentChatroomId = chatroomId

  subscription = consumer.subscriptions.create(
    { channel: "ChatroomChannel", chatroom_id: chatroomId },
    {
      received(data) {
        if (data.type === "message") {
          appendMessage(data, currentAccountId)
          scrollToBottom()
          window.dispatchEvent(new CustomEvent('voice-note-init'))
        } else if (data.type === "read_receipt") {
          updateReadReceipt(data)
        }
      }
    }
  )
}

function appendMessage(message, currentAccountId) {
  const messagesContainer = document.getElementById("messages-container")
  if (!messagesContainer) return

  const isOwnMessage = message.account_id === currentAccountId

  let attachmentHtml = ""
  if (message.attachment_url) {
    if (message.attachment_content_type && message.attachment_content_type.startsWith('image/')) {
      attachmentHtml = `<img src="${message.attachment_url}" class="rounded-lg max-w-full max-h-64 object-cover cursor-pointer hover:opacity-90 mb-2" />`
    } else if (message.attachment_content_type && message.attachment_content_type.startsWith('video/')) {
      attachmentHtml = `<video controls class="rounded-lg max-w-full max-h-64 mb-2"><source src="${message.attachment_url}" /></video>`
    } else if (message.message_type === 'voice_note') {
      attachmentHtml = `
        <div class="voice-note-player mb-2 relative" data-audio-url="${message.attachment_url}" data-message-id="${message.id}">
          <div class="flex items-center gap-3 p-2 bg-[#f0f2f5] rounded-lg w-fit">
            <button class="play-btn w-10 h-10 rounded-full bg-[#00a884] flex items-center justify-center text-white hover:bg-[#008069] transition-colors flex-shrink-0 shadow-sm">
              <svg class="play-icon w-5 h-5" fill="currentColor" viewBox="0 0 24 24">
                <path d="M8 5v14l11-7z"/>
              </svg>
              <svg class="pause-icon w-5 h-5 hidden" fill="currentColor" viewBox="0 0 24 24">
                <path d="M6 19h4V5H6v14zm8-14v14h4V5h-4z"/>
              </svg>
            </button>
            <div class="flex-1 flex flex-col gap-1 min-w-[160px]">
              <div class="waveform-container h-8 relative flex items-center overflow-hidden rounded-sm">
                <div class="waveform-placeholder absolute inset-0 flex items-center gap-[3px] px-1">
                  ${Array(25).fill().map(() => `<div class="w-1 bg-[#c5c9c7] rounded-full" style="height: ${Math.floor(Math.random() * 70 + 30)}%;"></div>`).join('')}
                </div>
                <div class="waveform-progress absolute inset-0 flex items-center gap-[3px] px-1 overflow-hidden" style="width: 0%;">
                  ${Array(25).fill().map(() => `<div class="w-1 bg-[#00a884] rounded-full" style="height: ${Math.floor(Math.random() * 70 + 30)}%;"></div>`).join('')}
                </div>
              </div>
              <span class="duration text-[10px] text-[#667781] font-mono">0:00</span>
            </div>
          </div>
        </div>
      `
    } else {
      attachmentHtml = `
        <div class="flex items-center gap-3 p-2 bg-[#f0f2f5] rounded-lg mb-2">
          <div class="w-10 h-10 rounded-full bg-[#00a884] flex items-center justify-center">
            <svg xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
            </svg>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-[#111b21] truncate">${message.attachment_filename || 'File'}</p>
          </div>
        </div>
      `
    }
  }

  let replyHtml = ""
  if (message.reply_to) {
    replyHtml = `
      <div class="border-l-4 border-[#00a884] pl-3 mb-2 py-1 bg-[#f0f2f5] rounded">
        <p class="text-xs text-[#00a884] font-medium">${escapeHtml(message.reply_to.username)}</p>
        <p class="text-sm text-[#667781] truncate">${escapeHtml(message.reply_to.body || '[Media]')}</p>
      </div>
    `
  }

  const messageHtml = `
    <div class="flex ${isOwnMessage ? 'justify-end' : 'justify-start'} mb-2 group" data-message-id="${message.id}">
      ${!isOwnMessage ? `
        <div class="w-8 h-8 rounded-full bg-[#d1d7db] flex items-center justify-center mr-2 flex-shrink-0 self-end">
          ${message.avatar_url
            ? `<img src="${message.avatar_url}" class="w-8 h-8 rounded-full object-cover" />`
            : `<span class="text-sm font-medium text-[#54656f]">${(message.username || 'U')[0].toUpperCase()}</span>`
          }
        </div>
      ` : ''}
      <div class="max-w-[75%] ${isOwnMessage ? 'bg-[#d9fdd3]' : 'bg-white'} rounded-lg ${isOwnMessage ? 'rounded-tr-none' : 'rounded-tl-none'} shadow-sm px-3 py-2 relative">
        ${replyHtml}
        ${attachmentHtml}
        ${message.body ? `<p class="text-[#111b21] break-words whitespace-pre-wrap">${escapeHtml(message.body)}</p>` : ''}
        <div class="flex items-center justify-end gap-1 mt-1">
          <span class="text-[10px] text-[#667781]">${message.created_at}</span>
        </div>
      </div>
      ${isOwnMessage ? `
        <div class="w-8 h-8 rounded-full bg-[#00a884] flex items-center justify-center ml-2 flex-shrink-0 self-end">
          ${message.avatar_url
            ? `<img src="${message.avatar_url}" class="w-8 h-8 rounded-full object-cover" />`
            : `<span class="text-sm font-medium text-white">${(message.username || 'U')[0].toUpperCase()}</span>`
          }
        </div>
      ` : ''}
    </div>
  `

  messagesContainer.insertAdjacentHTML("beforeend", messageHtml)
}

function escapeHtml(text) {
  const div = document.createElement('div')
  div.textContent = text
  return div.innerHTML
}

function updateReadReceipt(data) {
  const messageEl = document.querySelector(`[data-message-id="${data.message_id}"]`)
  if (messageEl) {
    const footer = messageEl.querySelector('.flex.items-center.justify-end')
    if (footer) {
      footer.innerHTML = `
        <span class="text-[10px] text-[#667781]">${data.read_at}</span>
        <div class="w-4 h-4 rounded-full bg-[#34c759] flex items-center justify-center">
          <svg class="h-2.5 w-2.5 text-white" viewBox="0 0 12 10" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M1 4.5L4.5 8L11 1" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        </div>
      `
    }
  }
}

function scrollToBottom() {
  const messagesContainer = document.getElementById("messages-container")
  if (messagesContainer) {
    messagesContainer.scrollTop = messagesContainer.scrollHeight
  }
}

window.scroll_bottom = function(){
  const messagesContainer = document.getElementById("messages-container");
  if (messagesContainer) {
    messagesContainer.scrollTop = messagesContainer.scrollHeight;
  }
}

document.addEventListener("turbo:load", setupChatroomSubscription)
document.addEventListener("DOMContentLoaded", setupChatroomSubscription)