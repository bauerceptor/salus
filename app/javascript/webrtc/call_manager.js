class CallManager {
  constructor(options = {}) {
    this.currentAccountId = options.currentAccountId;
    this.chatroomId = options.chatroomId;
    this.otherAccountId = options.otherAccountId;
    this.otherUsername = options.otherUsername;
    this.onIncomingCall = options.onIncomingCall || (() => {});
    this.onCallEnded = options.onCallEnded || (() => {});
    this.onError = options.onError || ((err) => console.error('CallManager error:', err));

    this.peer = null;
    this.peerId = null;
    this.call = null;
    this.localStream = null;
    this.remoteStream = null;
    this.callState = 'idle';
    this.callType = 'audio';
    this.callStartTime = null;
    this.peerConnection = null;

    this.iceServers = [
      { urls: 'stun:stun.l.google.com:19302' },
      { urls: 'stun:stun1.l.google.com:19302' }
    ];

    this.csrfToken = document.querySelector('meta[name="csrf-token"]')?.content;
  }

  async initialize() {
    await this.initPeer();
  }

  async initPeer() {
    return new Promise((resolve, reject) => {
      const peerId = `account_${this.currentAccountId}_${Date.now()}`;

      if (window.Peer) {
        this.peer = new window.Peer(peerId, {
          host: window.location.hostname,
          port: 9000,
          path: '/peerjs',
          debug: 1
        });
      } else {
        console.warn('PeerJS not loaded, WebRTC calls will not work')
        return resolve()
      }

      this.peer.on('open', (id) => {
        this.peerId = id;
        console.log('PeerJS connected with ID:', id);
        resolve();
      });

      this.peer.on('error', (err) => {
        console.error('PeerJS error:', err);
        this.onError(err);
      });

      this.peer.on('call', (call) => {
        this.incomingCall = call;
        this.callState = 'incoming';
        this._handleIncomingCall(call);
      });
    });
  }

  async startCall(accountId, username, callType = 'audio') {
    this.otherAccountId = accountId;
    this.otherUsername = username;
    this.callType = callType;

    try {
      this.localStream = await navigator.mediaDevices.getUserMedia({
        audio: true,
        video: callType === 'video'
      });

      const call = this.peer.call(
        `account_${accountId}_${Date.now()}`,
        this.localStream
      );

      this.call = call;
      this.callState = 'calling';

      this._setupCallHandlers(call);

      if (callType === 'video') {
        this._showLocalVideo();
      }
    } catch (err) {
      this.onError(err);
    }
  }

  acceptCall() {
    if (this.incomingCall) {
      navigator.mediaDevices.getUserMedia({ audio: true, video: this.callType === 'video' })
        .then((stream) => {
          this.localStream = stream;
          this.incomingCall.answer(stream);
          this.call = this.incomingCall;
          this._setupCallHandlers(this.incomingCall);
          this.callState = 'connected';

          if (this.callType === 'video') {
            this._showLocalVideo();
          }
        })
        .catch(this.onError);
    }
  }

  rejectCall() {
    if (this.incomingCall) {
      this.incomingCall.close();
      this.incomingCall = null;
      this.callState = 'idle';
    }
  }

  endCall() {
    if (this.call) {
      this.call.close();
      this.call = null;
    }

    if (this.localStream) {
      this.localStream.getTracks().forEach(track => track.stop());
      this.localStream = null;
    }

    if (this.remoteStream) {
      this.remoteStream.getTracks().forEach(track => track.stop());
      this.remoteStream = null;
    }

    this.callState = 'idle';
    this.callStartTime = null;

    this._hideCallModals();
  }

  toggleMute() {
    if (this.localStream) {
      const audioTrack = this.localStream.getAudioTracks()[0];
      if (audioTrack) {
        audioTrack.enabled = !audioTrack.enabled;
        return !audioTrack.enabled;
      }
    }
    return false;
  }

  toggleVideo() {
    if (this.localStream) {
      const videoTrack = this.localStream.getVideoTracks()[0];
      if (videoTrack) {
        videoTrack.enabled = !videoTrack.enabled;
        return !videoTrack.enabled;
      }
    }
    return false;
  }

  _setupCallHandlers(call) {
    call.on('stream', (stream) => {
      this.remoteStream = stream;
      this._showRemoteStream(stream);
    });

    call.on('close', () => {
      this.endCall();
    });

    call.on('error', (err) => {
      this.onError(err);
    });

    call.peerConnection.onicecandidate = (event) => {
      if (event.candidate) {
        window.CallChannel?.sendIceCandidate(this.otherAccountId, event.candidate)
      }
    };
  }

  _handleIncomingCall(call) {
    const modal = document.getElementById('call-modal')
    if (modal) {
      modal.classList.remove('hidden')
      modal.querySelector('.call-status').textContent = 'Incoming...'
    }
  }

  _showLocalVideo() {
    const localVideoEl = document.getElementById('local-video')
    if (localVideoEl && this.localStream) {
      localVideoEl.srcObject = this.localStream
      localVideoEl.classList.remove('hidden')
    }
  }

  _showRemoteStream(stream) {
    const remoteVideoEl = document.getElementById('remote-video')
    if (remoteVideoEl) {
      remoteVideoEl.srcObject = stream
    }
  }

  _hideCallModals() {
    const modal = document.getElementById('call-modal')
    if (modal) {
      modal.classList.add('hidden')
    }

    const localVideoEl = document.getElementById('local-video')
    if (localVideoEl) {
      localVideoEl.srcObject = null
      localVideoEl.classList.add('hidden')
    }

    const remoteVideoEl = document.getElementById('remote-video')
    if (remoteVideoEl) {
      remoteVideoEl.srcObject = null
    }
  }

  onIncomingCall(data) {
    this.incomingCallData = data
  }

  onOffer(data) {
    // Handle incoming WebRTC offer
  }

  onAnswer(data) {
    // Handle incoming WebRTC answer
  }

  onIceCandidate(data) {
    // Handle incoming ICE candidate
  }
}

window.CallManager = CallManager;