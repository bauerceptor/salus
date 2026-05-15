// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails";
import "controllers";
import "fslightbox";
import "chartkick";
import "Chart.bundle";
import "chart.js";
import "tom-select";
import "conversations";
import "ai_agent";
import "dashboard_charts";
import "channels/chatroom_channel";
import "voice_recorder";
import "voice_note_player";
import "webrtc/call_manager";

addEventListener("turbo:load", () => {
  if (document.body.dataset.gallery === "true") {
    refreshFsLightbox();
  }
  window.scroll_bottom?.();
});
