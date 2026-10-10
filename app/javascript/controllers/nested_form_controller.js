import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["target", "template"]

  connect() {
    this.updatePositions()
  }

  add(e) {
    e.preventDefault()
    // Use a unique ID based on timestamp
    const uniqueId = new Date().getTime()

    let content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, uniqueId)
    this.targetTarget.insertAdjacentHTML('beforeend', content)

    this.updatePositions()
  }

  remove(e) {
    e.preventDefault()
    const wrapper = e.target.closest('.nested-fields')
    let removed = false
    const finish = () => {
      if (removed) return
      removed = true
      if (wrapper.dataset.newRecord === 'true') {
        wrapper.remove()
      } else {
        wrapper.style.display = 'none'
        // Hidden fields can't be filled in, so they mustn't block submission
        wrapper.querySelectorAll('[required]').forEach((input) => input.required = false)
        const destroyInput = wrapper.querySelector("input[name*='_destroy']")
        if (destroyInput) destroyInput.value = '1'
      }
      this.updatePositions()
    }

    // Let the exit animation play first; the timeout covers browsers that skip it
    wrapper.classList.add('removing')
    wrapper.addEventListener('animationend', (event) => { if (event.target === wrapper) finish() })
    setTimeout(finish, 500)
  }

  // Positions are numbered 1, 2, 3… in display order, skipping removed questions
  updatePositions() {
    let currentPosition = 1
    this.targetTarget.querySelectorAll('.nested-fields').forEach((field) => {
      if (field.style.display !== 'none') {
        const positionInput = field.querySelector('.question-position-input')
        const positionLabel = field.querySelector('.question-position-label')
        if (positionInput) positionInput.value = currentPosition
        if (positionLabel) positionLabel.textContent = `Question ${currentPosition}`
        currentPosition++
      }
    })
  }
}
