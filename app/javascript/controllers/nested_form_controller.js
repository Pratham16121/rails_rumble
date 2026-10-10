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
    
    // Calculate the next position number (1-indexed based on current number of visible questions)
    // Wait, the backend validates position: uniqueness { scope: :quiz_session_id }.
    // If they all submit with position = uniqueId, that's fine but position is meant to be 1, 2, 3...
    // Let's just calculate position sequentially for display, but for the DB, position needs to be unique.
    
    let content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, uniqueId)
    this.targetTarget.insertAdjacentHTML('beforeend', content)
    
    this.updatePositions()
  }

  remove(e) {
    e.preventDefault()
    const wrapper = e.target.closest('.nested-fields')
    if (wrapper.dataset.newRecord === 'true') {
      wrapper.remove()
    } else {
      wrapper.style.display = 'none'
      const destroyInput = wrapper.querySelector("input[name*='_destroy']")
      if (destroyInput) destroyInput.value = '1'
    }
    this.updatePositions()
  }

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
