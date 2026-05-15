import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="reset_form"
export default class extends Controller {
  connect() {
    this.boundClear = this.clear.bind(this);
    this.element.addEventListener("submit", this.boundClear);
  }

  disconnect() {
    this.element.removeEventListener("submit", this.boundClear);
  }

  clear(event) {
    setTimeout(() => {
      this.element.reset();
      this.element
        .querySelectorAll(".dash-form__group__error")
        .forEach((error) => {
          error.remove();
        });
    }, 0);
  }
}
