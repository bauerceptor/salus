import { Controller } from "@hotwired/stimulus";

export default class PatientFilterController extends Controller {
  static targets = ["filterBar"];

  search(event) {
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      event.target.form.submit();
    }, 300);
  }

  filter(event) {
    event.preventDefault();
    const url = event.currentTarget.href;
    window.location.href = url;
  }
}