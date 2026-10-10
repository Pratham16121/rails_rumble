import { Controller } from "@hotwired/stimulus"

// Counts down the time left on the current question, draining the ring as it goes.
// When it hits zero, hides the "open" targets (e.g. answer buttons) and shows the "closed" ones.
// The server sends seconds remaining rather than an end time, so device clock skew doesn't matter.
// On the host screen, an "autoReveal" form is submitted once time is up, so the reveal happens by itself.

// Matches QuizSession::ANSWER_GRACE_PERIOD, plus a little network slack, so late answers still count
const AUTO_REVEAL_DELAY_MS = 1500

export default class extends Controller {
  static targets = ["remaining", "open", "closed", "ring", "autoReveal"]
  static values = { seconds: Number, total: Number }

  connect() {
    this.endsAt = Date.now() + this.secondsValue * 1000
    this.ringTargets.forEach((ring) => {
      ring.circumference = 2 * Math.PI * ring.r.baseVal.value
      ring.style.strokeDasharray = ring.circumference
    })
    this.tick()
  }

  disconnect() {
    cancelAnimationFrame(this.frame)
    clearTimeout(this.autoRevealTimer)
  }

  tick = () => {
    const msLeft = Math.max(0, this.endsAt - Date.now())
    const remaining = Math.ceil(msLeft / 1000)
    const fraction = this.totalValue > 0 ? msLeft / (this.totalValue * 1000) : 0

    this.remainingTargets.forEach((target) => target.textContent = remaining)
    this.ringTargets.forEach((ring) => ring.style.strokeDashoffset = ring.circumference * (1 - fraction))
    this.element.classList.toggle("urgent", remaining > 0 && remaining <= 5)

    if (remaining === 0) {
      this.element.classList.add("done")
      this.openTargets.forEach((target) => target.hidden = true)
      this.closedTargets.forEach((target) => target.hidden = false)
      if (this.hasAutoRevealTarget) {
        this.autoRevealTimer = setTimeout(() => this.autoRevealTarget.requestSubmit(), AUTO_REVEAL_DELAY_MS)
      }
    } else {
      this.frame = requestAnimationFrame(this.tick)
    }
  }
}
