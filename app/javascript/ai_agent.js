document.addEventListener('turbo:load', function() {
  const aiAgentLayout = document.querySelector('.salus-ai');
  if (!aiAgentLayout) return;

  // Elements
  const messageForm = document.getElementById('aiMessageForm');
  const messageInput = document.getElementById('aiMessageInput');
  const messagesContainer = document.getElementById('messagesContainer');
  const imageInput = document.getElementById('imageInput');
  const pdfInput = document.getElementById('pdfInput');
  const attachImageBtn = document.getElementById('attachImageBtn');
  const attachPdfBtn = document.getElementById('attachPdfBtn');
  const voiceBtn = document.getElementById('voiceBtn');
  const voiceSendBtn = document.getElementById('voiceSendBtn');
  const sendBtn = document.getElementById('sendBtn');
  const conversationIdInput = document.getElementById('conversationId');
  const attachmentPreview = document.getElementById('attachmentPreview');
  const imageDataInput = document.getElementById('imageData');
  const pdfDataInput = document.getElementById('pdfData');
  const pdfNameInput = document.getElementById('pdfName');
  const voiceDataInput = document.getElementById('voiceData');
  const voiceFormatInput = document.getElementById('voiceFormat');
  const voiceRecording = document.getElementById('voiceRecording');
  const voiceRecordingTime = document.getElementById('voiceRecordingTime');
  const cancelVoiceRecording = document.getElementById('cancelVoiceRecording');
  const startNewChat = document.getElementById('startNewChat');
  const newChatBtn = document.getElementById('newChatBtn');

  // State
  let mediaRecorder = null;
  let audioChunks = [];
  let recordingStartTime = null;
  let recordingTimer = null;
  let currentAttachment = null;

  // Utilities
  function fileToBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  function simpleFormat(text) {
    if (!text) return '';
    return text.split('\n').map(line => `<p>${line}</p>`).join('');
  }

  function showAttachmentPreview(type, data, name) {
    currentAttachment = { type, data, name };
    attachmentPreview.style.display = 'flex';

    if (type === 'image') {
      attachmentPreview.innerHTML = `<img src="${data}" style="width: 2rem; height: 2rem; object-fit: cover; border-radius: 4px;"> <span>${escapeHtml(name)}</span>`;
    } else if (type === 'pdf') {
      attachmentPreview.innerHTML = `<i class="ri-file-pdf-line" style="color: #ef4444; font-size: 1.25rem;"></i> <span>${escapeHtml(name)}</span>`;
    } else if (type === 'voice') {
      attachmentPreview.innerHTML = `<i class="ri-mic-line" style="color: #0d7377; font-size: 1.25rem;"></i> <span>Voice message</span>`;
    }
  }

  function clearAttachment() {
    currentAttachment = null;
    attachmentPreview.style.display = 'none';
    attachmentPreview.innerHTML = '';
    imageDataInput.value = '';
    pdfDataInput.value = '';
    pdfNameInput.value = '';
    voiceDataInput.value = '';
    imageInput.value = '';
    pdfInput.value = '';
  }

  function scrollToBottom() {
    if (messagesContainer) {
      messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }
  }

  // Attachment handlers
  if (attachImageBtn && imageInput) {
    attachImageBtn.addEventListener('click', () => imageInput.click());
    imageInput.addEventListener('change', async (e) => {
      const file = e.target.files[0];
      if (file) {
        const base64 = await fileToBase64(file);
        imageDataInput.value = base64;
        showAttachmentPreview('image', base64, file.name);
      }
    });
  }

  if (attachPdfBtn && pdfInput) {
    attachPdfBtn.addEventListener('click', () => pdfInput.click());
    pdfInput.addEventListener('change', async (e) => {
      const file = e.target.files[0];
      if (file) {
        const base64 = await fileToBase64(file);
        pdfDataInput.value = base64;
        pdfNameInput.value = file.name;
        showAttachmentPreview('pdf', base64, file.name);
      }
    });
  }

  // Message input auto-resize
  if (messageInput) {
    messageInput.addEventListener('input', function() {
      this.style.height = 'auto';
      this.style.height = Math.min(this.scrollHeight, 128) + 'px';
    });
  }

  // Voice recording
  if (voiceBtn) {
    voiceBtn.addEventListener('click', async () => {
      if (mediaRecorder && mediaRecorder.state === 'recording') {
        stopRecording();
      } else {
        await startRecording();
      }
    });
  }

  async function startRecording() {
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      mediaRecorder = new MediaRecorder(stream);
      audioChunks = [];

      mediaRecorder.ondataavailable = (e) => {
        audioChunks.push(e.data);
      };

      mediaRecorder.onstop = async () => {
        const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
        const base64 = await fileToBase64(audioBlob);

        voiceDataInput.value = base64;
        voiceFormatInput.value = 'webm';
        showAttachmentPreview('voice', base64, 'voice.webm');

        stream.getTracks().forEach(track => track.stop());

        messageInput.style.display = 'none';
        sendBtn.style.display = 'none';
        voiceSendBtn.style.display = 'flex';
        voiceRecording.style.display = 'none';
        voiceBtn.classList.remove('recording');
      };

      mediaRecorder.start();
      recordingStartTime = Date.now();
      voiceRecording.style.display = 'flex';
      voiceBtn.classList.add('recording');

      recordingTimer = setInterval(() => {
        const elapsed = Math.round((Date.now() - recordingStartTime) / 1000);
        const minutes = Math.floor(elapsed / 60);
        const seconds = elapsed % 60;
        voiceRecordingTime.textContent = `${minutes}:${seconds.toString().padStart(2, '0')}`;
      }, 1000);

    } catch (error) {
      console.error('Error starting recording:', error);
      alert('Could not access microphone. Please check permissions.');
    }
  }

  function stopRecording() {
    if (mediaRecorder && mediaRecorder.state === 'recording') {
      mediaRecorder.stop();
      clearInterval(recordingTimer);
    }
  }

  if (cancelVoiceRecording) {
    cancelVoiceRecording.addEventListener('click', () => {
      stopRecording();
      voiceRecording.style.display = 'none';
      voiceBtn.classList.remove('recording');
      clearAttachment();
      messageInput.style.display = 'block';
      sendBtn.style.display = 'flex';
      voiceSendBtn.style.display = 'none';
      audioChunks = [];
    });
  }

  // Voice send handler
  if (voiceSendBtn) {
    voiceSendBtn.addEventListener('click', async () => {
      if (!voiceDataInput.value) return;

      voiceSendBtn.disabled = true;
      voiceSendBtn.innerHTML = '<i class="ri-loader-2-line" style="animation: spin 1s linear infinite;"></i>';

      try {
        const response = await fetch('/ai-agent/transcribe', {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
          },
          body: JSON.stringify({
            audio_data: voiceDataInput.value,
            format: 'webm'
          })
        });

        const data = await response.json();

        if (data.transcription) {
          messageInput.value = data.transcription;
          await submitForm();
        } else {
          alert('Could not transcribe audio. Please try again.');
        }
      } catch (error) {
        console.error('Transcription error:', error);
        alert('Transcription failed. Please try again.');
      } finally {
        voiceSendBtn.disabled = false;
        voiceSendBtn.innerHTML = '<i class="ri-send-plane-fill"></i>';
        voiceSendBtn.style.display = 'none';
        messageInput.style.display = 'block';
        sendBtn.style.display = 'flex';
        clearAttachment();
      }
    });
  }

  // Form submission
  async function submitForm() {
    if (!messageInput.value.trim() && !imageDataInput.value && !pdfDataInput.value && !voiceDataInput.value) {
      return;
    }

    const submitBtn = sendBtn;
    submitBtn.disabled = true;
    submitBtn.innerHTML = '<i class="ri-loader-2-line" style="animation: spin 1s linear infinite;"></i>';

    // Add user message to UI
    const userMessageDiv = document.createElement('div');
    userMessageDiv.className = 'salus-ai__bubble salus-ai__bubble--sent';
    userMessageDiv.innerHTML = `
      <div class="salus-ai__bubble-content">
        <p class="salus-ai__bubble-text">${escapeHtml(messageInput.value || '')}</p>
        ${currentAttachment ? renderAttachment(currentAttachment) : ''}
      </div>
      <span class="salus-ai__bubble-time">${new Date().toLocaleTimeString('en', { hour: '2-digit', minute: '2-digit' })}</span>
    `;
    messagesContainer.appendChild(userMessageDiv);
    scrollToBottom();

    // Add thinking indicator
    const thinkingDiv = document.createElement('div');
    thinkingDiv.className = 'salus-ai__bubble salus-ai__bubble--thinking';
    thinkingDiv.innerHTML = `
      <div class="salus-ai__bubble-content">
        <p class="salus-ai__bubble-text">Thinking...</p>
      </div>
    `;
    messagesContainer.appendChild(thinkingDiv);
    scrollToBottom();

try {
      const formData = new FormData();
      formData.append('content', messageInput.value);
      formData.append('conversation_id', conversationIdInput.value);
      if (imageDataInput.value) formData.append('image_data', imageDataInput.value);
      if (pdfDataInput.value) {
        formData.append('pdf_data', pdfDataInput.value);
        formData.append('pdf_name', pdfNameInput.value);
      }
      if (voiceDataInput.value) {
        formData.append('voice_data', voiceDataInput.value);
        formData.append('voice_format', 'webm');
      }

      const response = await fetch('/ai-agent/messages', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: formData
      });

      if (!response.ok) {
        throw new Error(`Server error: ${response.status} ${response.statusText}`);
      }

      const data = await response.json();
      console.log('Server response:', data);

      messagesContainer.removeChild(thinkingDiv);

      if (data.ai_response) {
        const aiMessageDiv = document.createElement('div');
        aiMessageDiv.className = 'salus-ai__bubble salus-ai__bubble--received';
        aiMessageDiv.innerHTML = `
          <div class="salus-ai__bubble-content">
            <p class="salus-ai__bubble-text">${simpleFormat(data.ai_response.content)}</p>
            <button class="salus-ai__speak-btn" data-text="${escapeHtml(data.ai_response.content)}" title="Listen">
              <i class="ri-volume-up-line"></i>
            </button>
          </div>
          <span class="salus-ai__bubble-time">${data.ai_response.created_at}</span>
        `;
        messagesContainer.appendChild(aiMessageDiv);

        // Attach speak button handler
        const speakBtn = aiMessageDiv.querySelector('.salus-ai__speak-btn');
        if (speakBtn) {
          speakBtn.addEventListener('click', handleSpeak);
        }
      }

      if (data.conversation_id && data.conversation_id !== conversationIdInput.value) {
        conversationIdInput.value = data.conversation_id;
      }

    } catch (error) {
      console.error('Error sending message:', error);
      messagesContainer.removeChild(thinkingDiv);

      const errorDiv = document.createElement('div');
      errorDiv.className = 'salus-ai__bubble salus-ai__bubble--received';
      errorDiv.innerHTML = `
        <div class="salus-ai__bubble-content">
          <p class="salus-ai__bubble-text">Sorry, I encountered an error. Please try again.</p>
          <p class="salus-ai__bubble-text" style="font-size: 0.75rem; color: #666; margin-top: 0.5rem;">Error: ${escapeHtml(error.message)}</p>
        </div>
        <span class="salus-ai__bubble-time">${new Date().toLocaleTimeString('en', { hour: '2-digit', minute: '2-digit' })}</span>
      `;
      messagesContainer.appendChild(errorDiv);
    }

    submitBtn.disabled = false;
    submitBtn.innerHTML = '<i class="ri-send-plane-fill"></i>';
    messageInput.value = '';
    messageInput.style.height = 'auto';
    clearAttachment();
    scrollToBottom();
  }

  function renderAttachment(attachment) {
    if (!attachment) return '';
    if (attachment.type === 'image') {
      return `<div class="salus-ai__bubble-attachments"><img src="${attachment.data}" class="salus-ai__bubble-image" alt="Uploaded image"></div>`;
    } else if (attachment.type === 'pdf') {
      return `<div class="salus-ai__bubble-attachments"><div class="salus-ai__bubble-file"><i class="ri-file-pdf-line"></i><span>${escapeHtml(attachment.name)}</span></div></div>`;
    } else if (attachment.type === 'voice') {
      return `<div class="salus-ai__bubble-attachments"><div class="salus-ai__bubble-voice"><audio controls><source src="${attachment.data}" type="audio/webm"></audio></div></div>`;
    }
    return '';
  }

  // Speak button handler
  function handleSpeak(e) {
    const btn = e.currentTarget;
    const text = btn.dataset.text;
    if (!text) return;

    // If already speaking this button, stop
    if (btn.classList.contains('speaking')) {
      window.speechSynthesis.cancel();
      btn.classList.remove('speaking');
      btn.querySelector('i').className = 'ri-volume-up-line';
      return;
    }

    // Cancel any ongoing speech
    window.speechSynthesis.cancel();

    const utterance = new SpeechSynthesisUtterance(text);
    utterance.rate = 1;
    utterance.pitch = 1;

    utterance.onstart = () => {
      btn.classList.add('speaking');
      btn.querySelector('i').className = 'ri-volume-mute-line';
    };

    utterance.onend = () => {
      btn.classList.remove('speaking');
      btn.querySelector('i').className = 'ri-volume-up-line';
    };

    utterance.onerror = () => {
      btn.classList.remove('speaking');
      btn.querySelector('i').className = 'ri-volume-up-line';
    };

    window.speechSynthesis.speak(utterance);
  }

  // Form submit handler
  if (messageForm) {
    messageForm.addEventListener('submit', async (e) => {
      e.preventDefault();
      await submitForm();
    });
  }

  // Send button click
  if (sendBtn) {
    sendBtn.addEventListener('click', async () => {
      await submitForm();
    });
  }

  // New conversation handlers
  if (startNewChat) {
    startNewChat.addEventListener('click', createNewConversation);
  }

  if (newChatBtn) {
    newChatBtn.addEventListener('click', createNewConversation);
  }

  async function createNewConversation() {
    try {
      const response = await fetch('/ai-agent/conversations', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        }
      });

      const data = await response.json();

      if (data.conversation_id) {
        window.location.href = `/en/ai-agent?conversation_id=${data.conversation_id}`;
      }
    } catch (error) {
      console.error('Error creating conversation:', error);
    }
  }

  // Chat item click handlers
  const chatItems = document.querySelectorAll('.salus-ai__chat-item');
  chatItems.forEach(item => {
    item.addEventListener('click', (e) => {
      if (e.target.closest('.salus-ai__chat-item__delete')) return;
      const convId = item.dataset.conversationId;
      if (convId) {
        window.location.href = `/en/ai-agent?conversation_id=${convId}`;
      }
    });
  });

  // Attach speak buttons to existing messages
  const speakButtons = document.querySelectorAll('.salus-ai__speak-btn');
  speakButtons.forEach(btn => {
    btn.addEventListener('click', handleSpeak);
  });

  // Initial scroll to bottom
  scrollToBottom();
});

// Spin animation for loading
const style = document.createElement('style');
style.textContent = `
  @keyframes spin {
    from { transform: rotate(0deg); }
    to { transform: rotate(360deg); }
  }
`;
document.head.appendChild(style);
