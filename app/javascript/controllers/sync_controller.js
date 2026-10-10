import { Controller } from "@hotwired/stimulus"
import { Turbo } from "@hotwired/turbo-rails"

// Live updates arrive over a websocket, so any sent while the page was reloading or the phone
// was asleep are lost. Whenever the live connection (re)connects or the page becomes visible
// again, this asks the server what the screen should show and reloads if the page is behind.
// The page's state is the data-sync-key attributes inside this element, joined in page order.

// Kept outside the controller so it survives Turbo page changes; stops a reload loop if keys ever disagree
let lastReloadAt = 0

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.source = document.querySelector("turbo-cable-stream-source")
    this.observer = new MutationObserver(() => {
      if (this.source.hasAttribute("connected")) this.check()
    })
    if (this.source) this.observer.observe(this.source, { attributes: true, attributeFilter: ["connected"] })

    this.checkWhenVisible = () => {
      if (document.visibilityState === "visible") this.check()
    }
    document.addEventListener("visibilitychange", this.checkWhenVisible)
  }

  disconnect() {
    this.observer.disconnect()
    document.removeEventListener("visibilitychange", this.checkWhenVisible)
  }

  async check() {
    try {
      const response = await fetch(this.urlValue, { headers: { Accept: "text/plain" } })
      if (!response.ok) return

      const serverKey = (await response.text()).trim()
      if (serverKey !== this.pageKey && Date.now() - lastReloadAt > 3000) {
        lastReloadAt = Date.now()
        Turbo.visit(window.location.href, { action: "replace" })
      }
    } catch {
      // Offline; the next reconnect will check again
    }
  }

  get pageKey() {
    return Array.from(this.element.querySelectorAll("[data-sync-key]"), (el) => el.dataset.syncKey).join("|")
  }
}
