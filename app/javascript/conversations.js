document.addEventListener('turbo:load', function() {
  const conversationsSection = document.querySelector('.whatsapp-layout');
  if (!conversationsSection) return;

  const conversationId = conversationsSection.dataset.conversationId;
  if (conversationId) {
    import("@hotwired/turbo-rails").then(async ({ createConsumer }) => {
      const consumer = await createConsumer();

      consumer.subscriptions.create({
        channel: "ConversationChannel",
        conversation_id: conversationId
      }, {
        received(data) {
          const messagesContainer = document.getElementById('messages');
          if (messagesContainer && !document.querySelector(`[data-message-id="${data.id}"]`)) {
            messagesContainer.insertAdjacentHTML('beforeend', renderMessageHTML(data));
            scrollToBottom(messagesContainer);

            const audio = document.getElementById(`audio-${data.id}`);
            if (audio) {
              const playButton = audio.closest('.whatsapp-message__voice')?.querySelector('.whatsapp-message__play');
              if (playButton) {
                playButton.addEventListener('click', () => {
                  if (audio.paused) {
                    audio.play();
                    playButton.innerHTML = '<i class="ri-pause-fill"></i>';
                  } else {
                    audio.pause();
                    playButton.innerHTML = '<i class="ri-play-fill"></i>';
                  }
                });
              }
            }
          }
        }
      });
    });
  }

  function renderMessageHTML(message) {
    const messageClass = message.is_sent ? 'whatsapp-message--sent' : 'whatsapp-message--received';
    let content = '';

    switch (message.message_type) {
      case 'text':
        content = `<p class="whatsapp-message__text">${escapeHtml(message.body || '')}</p>`;
        break;
      case 'voice':
        content = `
          <div class="whatsapp-message__voice">
            <button class="whatsapp-message__play">
              <i class="ri-play-fill"></i>
            </button>
            <div class="whatsapp-message__waveform">
              <div class="whatsapp-message__waveform-bar"></div>
              <div class="whatsapp-message__waveform-bar"></div>
              <div class="whatsapp-message__waveform-bar"></div>
              <div class="whatsapp-message__waveform-bar"></div>
              <div class="whatsapp-message__waveform-bar"></div>
            </div>
            <span class="whatsapp-message__duration">${message.duration}s</span>
            <audio id="audio-${message.id}" src="${message.attachment_url}"></audio>
          </div>`;
        break;
      case 'image':
        content = `<img src="${message.attachment_url}" class="whatsapp-message__image" alt="Image">`;
        break;
      case 'document':
        content = `
          <div class="whatsapp-message__document">
            <i class="ri-file-3-line"></i>
            <div class="whatsapp-message__document-info">
              <span class="whatsapp-message__document-name">${escapeHtml(message.attachment_type || 'Document')}</span>
              <span class="whatsapp-message__document-size">0.0 MB</span>
            </div>
            <a href="${message.attachment_url}" download class="whatsapp-message__document-download">
              <i class="ri-download-line"></i>
            </a>
          </div>`;
        break;
    }

    return `
      <div class="whatsapp-message ${messageClass}" data-message-id="${message.id}">
        <div class="whatsapp-message__content">
          ${content}
          <div class="whatsapp-message__meta">
            <span class="whatsapp-message__time">${message.created_at}</span>
            ${message.is_sent ? '<span class="whatsapp-message__status"><i class="ri-check-line"></i></span>' : ''}
          </div>
        </div>
      </div>
    `;
  }

  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  function scrollToBottom(container) {
    container.scrollTop = container.scrollHeight;
  }

  const imageBtn = document.getElementById('imageBtn');
  const documentBtn = document.getElementById('documentBtn');
  const voiceBtn = document.getElementById('voiceBtn');
  const imageInput = document.getElementById('imageInput');
  const documentInput = document.getElementById('documentInput');
  const messageForm = document.getElementById('new_message_form');
  const messageBody = document.getElementById('message_body');
  const messageType = document.getElementById('message_type');
  const messageDuration = document.getElementById('message_duration');
  const voiceRecording = document.getElementById('voiceRecording');
  const voiceRecordingTime = document.getElementById('voiceRecordingTime');
  const cancelRecording = document.getElementById('cancelRecording');

  let mediaRecorder = null;
  let audioChunks = [];
  let recordingStartTime = null;
  let recordingTimer = null;

  function fileToBase64(file) {
    return new Promise((resolve, reject) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.onerror = reject;
      reader.readAsDataURL(file);
    });
  }

  async function handleFileSelect(file, type) {
    try {
      const base64 = await fileToBase64(file);
      document.getElementById('attachment_data').value = base64;
      document.getElementById('attachment_name').value = file.name;
      document.getElementById('message_type').value = type;

      if (type === 'image') {
        messageBody.value = '';
      }

      messageForm.submit();

      document.getElementById('attachment_data').value = '';
      document.getElementById('attachment_name').value = '';
      document.getElementById('message_type').value = 'text';
    } catch (error) {
      console.error('Error handling file:', error);
    }
  }

  if (imageBtn && imageInput) {
    imageBtn.addEventListener('click', () => imageInput.click());

    imageInput.addEventListener('change', (e) => {
      const file = e.target.files[0];
      if (file) {
        handleFileSelect(file, 'image');
      }
    });
  }

  if (documentBtn && documentInput) {
    documentBtn.addEventListener('click', () => documentInput.click());

    documentInput.addEventListener('change', (e) => {
      const file = e.target.files[0];
      if (file) {
        handleFileSelect(file, 'document');
      }
    });
  }

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

        document.getElementById('attachment_data').value = base64;
        document.getElementById('attachment_name').value = 'audio/webm';
        messageType.value = 'voice';

        const duration = Math.round((Date.now() - recordingStartTime) / 1000);
        messageDuration.value = duration;

        stream.getTracks().forEach(track => track.stop());

        messageForm.submit();
      };

      mediaRecorder.start();
      recordingStartTime = Date.now();

      voiceRecording.style.display = 'flex';
      messageBody.style.display = 'none';
      messageForm.querySelector('.whatsapp-input__send').style.display = 'none';
      voiceBtn.innerHTML = '<i class="ri-stop-fill"></i>';
      voiceBtn.style.color = '#dc2626';

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
      resetVoiceUI();
    }
  }

  function resetVoiceUI() {
    voiceRecording.style.display = 'none';
    messageBody.style.display = 'block';
    messageBody.value = '';
    messageForm.querySelector('.whatsapp-input__send').style.display = 'flex';
    voiceBtn.innerHTML = '<i class="ri-mic-line"></i>';
    voiceBtn.style.color = '#54656f';
    voiceRecordingTime.textContent = '0:00';
  }

  if (cancelRecording) {
    cancelRecording.addEventListener('click', () => {
      stopRecording();
      resetVoiceUI();
    });
  }

  const audioElements = document.querySelectorAll('.whatsapp-message audio');
  audioElements.forEach(audio => {
    const playButton = audio.closest('.whatsapp-message__voice')?.querySelector('.whatsapp-message__play');
    if (playButton) {
      playButton.addEventListener('click', () => {
        if (audio.paused) {
          audio.play();
          playButton.innerHTML = '<i class="ri-pause-fill"></i>';
        } else {
          audio.pause();
          playButton.innerHTML = '<i class="ri-play-fill"></i>';
        }
      });

      audio.onended = () => {
        playButton.innerHTML = '<i class="ri-play-fill"></i>';
      };
    }
  });
});