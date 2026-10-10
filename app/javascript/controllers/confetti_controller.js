import { Controller } from "@hotwired/stimulus"

const COLORS = ["#f43f5e", "#3b82f6", "#f59e0b", "#22c55e", "#ffd23f", "#ff5fa2", "#a993ff"]
const SHAPES = ["triangle", "diamond", "circle", "square"]
const LIFETIME = 260 // frames at 60Hz

// Bursts confetti shaped like the four answer shapes out of the element when it appears.
export default class extends Controller {
  static values = { count: { type: Number, default: 120 }, delay: { type: Number, default: 0 } }

  connect() {
    if (window.matchMedia("(prefers-reduced-motion: reduce)").matches) return
    this.delayTimer = setTimeout(() => this.burst(), this.delayValue)
  }

  burst() {
    this.canvas = document.createElement("canvas")
    this.canvas.className = "confetti-canvas"
    document.body.appendChild(this.canvas)

    const ratio = window.devicePixelRatio || 1
    this.canvas.width = window.innerWidth * ratio
    this.canvas.height = window.innerHeight * ratio
    this.canvasContext = this.canvas.getContext("2d")
    this.canvasContext.scale(ratio, ratio)

    const rect = this.element.getBoundingClientRect()
    const x = rect.left + rect.width / 2
    const y = rect.top + rect.height / 3
    this.pieces = Array.from({ length: this.countValue }, () => this.piece(x, y))
    this.lastFrame = performance.now()
    this.frame = requestAnimationFrame(this.draw)
  }

  disconnect() {
    clearTimeout(this.delayTimer)
    cancelAnimationFrame(this.frame)
    this.canvas?.remove()
  }

  piece(x, y) {
    const angle = -Math.PI / 2 + (Math.random() - 0.5) * Math.PI * 0.8
    const speed = 8 + Math.random() * 9
    return {
      x, y,
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      size: 7 + Math.random() * 8,
      rotation: Math.random() * Math.PI * 2,
      spin: (Math.random() - 0.5) * 0.3,
      phase: Math.random() * Math.PI * 2,
      color: COLORS[Math.floor(Math.random() * COLORS.length)],
      shape: SHAPES[Math.floor(Math.random() * SHAPES.length)],
      age: 0
    }
  }

  draw = (now) => {
    // Scale movement by elapsed time so 60Hz and 120Hz screens look the same
    const step = Math.min(3, (now - this.lastFrame) / 16.67)
    this.lastFrame = now
    const context = this.canvasContext
    context.clearRect(0, 0, window.innerWidth, window.innerHeight)

    this.pieces = this.pieces.filter((p) => p.age < LIFETIME && p.y < window.innerHeight + 40)
    this.pieces.forEach((p) => {
      p.age += step
      // Gravity with a low terminal speed and a sideways sway, so pieces flutter down like paper
      p.vy = Math.min(p.vy + 0.22 * step, 3.2)
      p.vx *= Math.pow(0.96, step)
      p.x += (p.vx + Math.sin(p.age / 12 + p.phase) * 0.9) * step
      p.y += p.vy * step
      p.rotation += p.spin * step

      context.save()
      context.globalAlpha = Math.min(1, (LIFETIME - p.age) / 50)
      context.translate(p.x, p.y)
      context.rotate(p.rotation)
      context.fillStyle = p.color
      this.drawShape(context, p.shape, p.size)
      context.restore()
    })

    if (this.pieces.length > 0) {
      this.frame = requestAnimationFrame(this.draw)
    } else {
      this.canvas.remove()
    }
  }

  drawShape(context, shape, size) {
    const half = size / 2
    context.beginPath()
    if (shape === "triangle") {
      context.moveTo(0, -half)
      context.lineTo(half, half)
      context.lineTo(-half, half)
    } else if (shape === "diamond") {
      context.moveTo(0, -half)
      context.lineTo(half, 0)
      context.lineTo(0, half)
      context.lineTo(-half, 0)
    } else if (shape === "circle") {
      context.arc(0, 0, half, 0, Math.PI * 2)
    } else {
      context.rect(-half, -half * 0.6, size, size * 0.6)
    }
    context.fill()
  }
}
