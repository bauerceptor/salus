export class AttachmentUpload {
  constructor(dropZoneId, fileInputId, previewId) {
    this.dropZone = document.getElementById(dropZoneId);
    this.fileInput = document.getElementById(fileInputId);
    this.preview = document.getElementById(previewId);

    if (!this.dropZone || !this.fileInput || !this.preview) {
      return;
    }

    this.init();
  }

  init() {
    ['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      this.dropZone.addEventListener(eventName, (e) => this.preventDefaults(e), false);
    });

    ['dragenter', 'dragover'].forEach(eventName => {
      this.dropZone.addEventListener(eventName, () => this.dropZone.classList.add('dragover'), false);
    });

    ['dragleave', 'drop'].forEach(eventName => {
      this.dropZone.addEventListener(eventName, () => this.dropZone.classList.remove('dragover'), false);
    });

    this.dropZone.addEventListener('drop', (e) => this.handleDrop(e), false);
    this.fileInput.addEventListener('change', (e) => this.handleFileSelect(e), false);
  }

  preventDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  handleDrop(e) {
    const dt = e.dataTransfer;
    const files = dt.files;
    this.handleFiles(files);
  }

  handleFileSelect(e) {
    const files = e.target.files;
    this.handleFiles(files);
  }

  handleFiles(files) {
    [...files].forEach(file => {
      this.addFileToPreview(file);
    });
  }

  addFileToPreview(file) {
    const reader = new FileReader();
    const item = document.createElement('div');
    item.className = 'attachment-preview__item';

    if (file.type.startsWith('image/')) {
      reader.onload = (e) => {
        item.innerHTML = `
          <img src="${e.target.result}" class="attachment-preview__image">
          <div class="attachment-preview__info">
            <p class="attachment-preview__name">${file.name}</p>
            <p class="attachment-preview__size">${this.formatSize(file.size)}</p>
          </div>
          <button type="button" class="attachment-preview__remove" data-remove="true">
            <i class="ri-close-line"></i>
          </button>
        `;
      };
      reader.readAsDataURL(file);
    } else {
      const icon = this.getFileIcon(file.type);
      item.innerHTML = `
        <div class="attachment-preview__icon">
          <i class="${icon}"></i>
        </div>
        <div class="attachment-preview__info">
          <p class="attachment-preview__name">${file.name}</p>
          <p class="attachment-preview__size">${this.formatSize(file.size)}</p>
        </div>
        <button type="button" class="attachment-preview__remove" data-remove="true">
          <i class="ri-close-line"></i>
        </button>
      `;
    }

    item.querySelector('[data-remove]')?.addEventListener('click', () => {
      item.remove();
    });

    this.preview.appendChild(item);
  }

  getFileIcon(type) {
    if (type.startsWith('video/')) return 'ri-video-line';
    if (type.startsWith('audio/')) return 'ri-mic-line';
    if (type.includes('pdf')) return 'ri-file-pdf-line';
    if (type.includes('word') || type.includes('document')) return 'ri-file-word-line';
    return 'ri-file-line';
  }

  formatSize(bytes) {
    if (bytes < 1024) return bytes + ' B';
    if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + ' KB';
    return (bytes / (1024 * 1024)).toFixed(1) + ' MB';
  }
}
