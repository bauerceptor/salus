class VoiceNotePlayer {
  constructor(container, audioUrl, options = {}) {
    this.container = container;
    this.audioUrl = audioUrl;
    this.options = options;
    this.wavesurfer = null;
    this.isPlaying = false;
    this.duration = 0;

    this.onPlayStateChange = options.onPlayStateChange || (() => {});
    this.onDurationChange = options.onDurationChange || (() => {});
    this.onTimeUpdate = options.onTimeUpdate || (() => {});
  }

  init() {
    if (!this.container || !this.audioUrl) return;

    import("wavesurfer").then((WaveSurfer) => {
      this.wavesurfer = WaveSurfer.create({
        container: this.container,
        waveColor: '#a8b2b8',
        progressColor: '#00a884',
        height: 40,
        barWidth: 2,
        barGap: 1,
        barRadius: 2,
        cursorWidth: 0,
        cursorColor: 'transparent',
        backend: 'WebAudio',
        interact: true,
        fillParent: true
      });

      this.wavesurfer.on('ready', () => {
        this.duration = this.wavesurfer.getDuration();
        this.onDurationChange(this.duration);
      });

      this.wavesurfer.on('play', () => {
        this.isPlaying = true;
        this.onPlayStateChange(true);
      });

      this.wavesurfer.on('pause', () => {
        this.isPlaying = false;
        this.onPlayStateChange(false);
      });

      this.wavesurfer.on('finish', () => {
        this.isPlaying = false;
        this.onPlayStateChange(false);
      });

      this.wavesurfer.on('timeupdate', (currentTime) => {
        this.onTimeUpdate(currentTime);
      });

      this.wavesurfer.on('error', (err) => {
        console.error('WaveSurfer error:', err);
      });

      this.wavesurfer.load(this.audioUrl);
    });
  }

  play() {
    if (this.wavesurfer) {
      this.wavesurfer.play();
    }
  }

  pause() {
    if (this.wavesurfer) {
      this.wavesurfer.pause();
    }
  }

  togglePlayPause() {
    if (this.wavesurfer) {
      this.wavesurfer.playPause();
    }
  }

  seekTo(progress) {
    if (this.wavesurfer) {
      this.wavesurfer.seekTo(progress);
    }
  }

  setVolume(volume) {
    if (this.wavesurfer) {
      this.wavesurfer.setVolume(volume);
    }
  }

  formatTime(seconds) {
    if (!seconds || isNaN(seconds)) return '0:00';
    const mins = Math.floor(seconds / 60);
    const secs = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }

  destroy() {
    if (this.wavesurfer) {
      this.wavesurfer.destroy();
      this.wavesurfer = null;
    }
  }
}

window.VoiceNotePlayer = VoiceNotePlayer;