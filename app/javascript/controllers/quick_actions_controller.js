import { Controller } from "@hotwired/stimulus";

export default class QuickActionsController extends Controller {
  static targets = ["searchModal", "searchInput", "searchResults"];

  openSearch() {
    this.searchModalTarget.classList.add("quick-actions-toolbar__search-modal--open");
    document.body.style.overflow = "hidden";
    setTimeout(() => {
      this.searchInputTarget.focus();
    }, 50);
  }

  closeSearch() {
    this.searchModalTarget.classList.remove("quick-actions-toolbar__search-modal--open");
    document.body.style.overflow = "";
    if (this.searchInputTarget) {
      this.searchInputTarget.value = "";
    }
    if (this.searchResultsTarget) {
      this.searchResultsTarget.innerHTML = "";
    }
  }

  closeOnBackdrop(event) {
    if (event.target === this.searchModalTarget) {
      this.closeSearch();
    }
  }

  handleSearchInput(event) {
    if (event.key === "Escape") {
      this.closeSearch();
      return;
    }
    if (this.debounceTimer) clearTimeout(this.debounceTimer);
    this.debounceTimer = setTimeout(() => {
      this.performSearch(event.target.value);
    }, 300);
  }

  async performSearch(query) {
    if (!query || query.length < 2) {
      this.searchResultsTarget.innerHTML = '<p class="quick-actions-toolbar__search-empty">Type at least 2 characters to search</p>';
      return;
    }

    this.searchResultsTarget.innerHTML = '<p class="quick-actions-toolbar__search-loading"><i class="ri-loader-line"></i> Searching...</p>';

    try {
      const response = await fetch(
        `/specialist/patients/search?q=${encodeURIComponent(query)}`,
        { headers: { Accept: "text/html" } }
      );
      const html = await response.text();
      const parser = new DOMParser();
      const doc = parser.parseFromString(html, "text/html");
      const results = doc.querySelector(".quick-actions-toolbar__search-results")?.innerHTML || "";
      this.searchResultsTarget.innerHTML = results;
    } catch {
      this.searchResultsTarget.innerHTML = '<p class="quick-actions-toolbar__search-empty">Search failed. Try again.</p>';
    }
  }

  async navigateToPatient(event) {
    const link = event.target.closest("a");
    if (!link) return;
    event.preventDefault();
    const url = link.href;
    this.closeSearch();
    await import("@hotwired/turbo").then(({ Turbo }) => {
      Turbo.visit(url, { action: "advance" });
    });
  }
}