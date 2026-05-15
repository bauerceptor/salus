class VoiceRecorder {
  constructor(options = {}) {
    this.chatroomId = options.chatroomId;
    this.locale = options.locale || 'en';
    this.onRecordingStateChange = options.onRecordingStateChange || (() => {});
    this.onDurationUpdate = options.onDurationUpdate || (() => {});
    this.onError = options.onError || ((err) => console.error('VoiceRecorder error:', err));
    this.onSent = options.onSent || (() => {});
    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;

    this.recording = false;
    this.mediaRecorder = null;
    this.audioChunks = [];
    this.stream = null;
    this.startTime = null;
    this.timerInterval = null;
    this.duration = 0;
    this.maxDuration = 300; // 5 minutes in seconds

    this.mimeType = this._getSupportedMimeType();
  }

  _getSupportedMimeType() {
    const types = [
      'audio/webm;codecs=opus',
      'audio/webm',
      'audio/ogg;codecs=opus',
      'audio/mp4',
      'audio/wav'
    ];

    for (const type of types) {
      if (MediaRecorder.isTypeSupported(type)) {
        return type;
      }
    }
    return 'audio/webm';
  }

  async startRecording() {
    if (this.recording) return;

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true });

      this.audioChunks = [];
      this.mediaRecorder = new MediaRecorder(this.stream, {
        mimeType: this.mimeType,
        audioBitsPerSecond: 128000
      });

      this.mediaRecorder.ondataavailable = (event) => {
        if (event.data && event.data.size > 0) {
          this.audioChunks.push(event.data);
        }
      };

      this.mediaRecorder.onstop = async () => {
        await this._sendRecording();
        this.onSent({ message_type: 'voice_note', body: 'Voice message' });
      };

      this.mediaRecorder.start(1000); // Collect data every second
      this.recording = true;
      this.startTime = Date.now();
      this.duration = 0;

      this.timerInterval = setInterval(() => {
        this.duration = Math.floor((Date.now() - this.startTime) / 1000);
        this.onDurationUpdate(this.duration);

        if (this.duration >= this.maxDuration) {
          this.stopRecording();
        }
      }, 1000);

      this.onRecordingStateChange(true);
    } catch (err) {
      this.onError(err);
    }
  }

  stopRecording() {
    if (!this.recording) return;

    if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
      this.mediaRecorder.stop();
    }

    this._stopMediaStream();
    this.recording = false;

    if (this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }

    this.onRecordingStateChange(false);
  }

  cancelRecording() {
    if (!this.recording) return;

    if (this.mediaRecorder && this.mediaRecorder.state !== 'inactive') {
      this.mediaRecorder.stop();
    }

    this.audioChunks = [];
    this._stopMediaStream();
    this.recording = false;

    if (this.timerInterval) {
      clearInterval(this.timerInterval);
      this.timerInterval = null;
    }

    this.onRecordingStateChange(false);
  }

  _stopMediaStream() {
    if (this.stream) {
      this.stream.getTracks().forEach((track) => track.stop());
      this.stream = null;
    }
  }

  async _sendRecording() {
    if (this.audioChunks.length === 0) return;

    const blob = new Blob(this.audioChunks, { type: this.mimeType });
    const filename = `voice_note_${Date.now()}.webm`;

    const formData = new FormData();
    formData.append('chatroom_message[body]', 'Voice message');
    formData.append('chatroom_message[message_type]', 'voice_note');
    formData.append('attachment', blob, filename);

    try {
      const response = await fetch(`/${this.locale}/chatrooms/${this.chatroomId}/chatroom_messages`, {
        method: 'POST',
        headers: {
          'X-CSRF-Token': this.csrfToken
        },
        body: formData
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.errors?.join(', ') || 'Failed to send voice note');
      }

      this.audioChunks = [];
      this.onSent({ message_type: 'voice_note', body: 'Voice message' });
    } catch (err) {
      this.onError(err);
    }
  }

  formatDuration(seconds) {
    const mins = Math.floor(seconds / 60);
    const secs = seconds % 60;
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
}

window.VoiceRecorder = VoiceRecorder;
