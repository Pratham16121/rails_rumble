import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.observer = new MutationObserver(() => {
      window.location.reload();
    });
    this.observer.observe(this.element, { childList: true, subtree: true, characterData: true });
  }

  disconnect() {
    this.observer.disconnect();
  }
}
