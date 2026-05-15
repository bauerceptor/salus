import { Controller } from "@hotwired/stimulus"

export default class CareStreamController extends Controller {
  static targets = ["timeline", "arrow"]

  toggle() {
    const isHidden = this.timelineTarget.hidden
    if (isHidden) {
      this.timelineTarget.hidden = false
      this.arrowTarget.classList.remove("ri-arrow-down-s-line")
      this.arrowTarget.classList.add("ri-arrow-up-s-line")
    } else {
      this.timelineTarget.hidden = true
      this.arrowTarget.classList.remove("ri-arrow-up-s-line")
      this.arrowTarget.classList.add("ri-arrow-down-s-line")
    }
  }
}
