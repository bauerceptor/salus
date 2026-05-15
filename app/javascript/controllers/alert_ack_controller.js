import { Controller } from "@hotwired/stimulus";

export default class AlertAckController extends Controller {
  static targets = ["resolveModal"];

  openResolveModal(event) {
    event.preventDefault();
    const button = event.currentTarget;
    const alertId = button.dataset.alertId;
    const modal = document.getElementById(`resolve_alert_${alertId}`);
    if (modal) {
      modal.style.display = "flex";
      document.body.style.overflow = "hidden";
    }
  }

  closeResolveModal(event) {
    if (event) event.preventDefault();
    const modal = event.currentTarget.closest(".resolve-modal");
    if (modal) {
      modal.style.display = "none";
      document.body.style.overflow = "";
    }
  }
}