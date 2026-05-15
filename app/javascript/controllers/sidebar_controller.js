import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["overlay"]

  collapse() {
    const sidebar = this.element.closest('.sidebar') || this.element
    sidebar.classList.add('collapsed')
    localStorage.setItem('sidebarCollapsed', 'true')
  }

  expand() {
    const sidebar = this.element.closest('.sidebar') || this.element
    sidebar.classList.remove('collapsed')
    localStorage.setItem('sidebarCollapsed', 'false')
  }

  toggle() {
    const sidebar = this.element.closest('.sidebar') || this.element
    sidebar.classList.toggle('collapsed')
    localStorage.setItem('sidebarCollapsed', sidebar.classList.contains('collapsed'))
  }

  connect() {
    const sidebar = this.element.closest('.sidebar') || this.element
    if (localStorage.getItem('sidebarCollapsed') === 'true') {
      sidebar.classList.add('collapsed')
    }
  }
}
