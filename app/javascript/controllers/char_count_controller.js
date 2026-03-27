import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "counter", "submit"]

  static values = {
    max: { type: Number, default: 500 },
    min: { type: Number, default: 5 }
  }

  connect() {
    this.update()
  }

  update() {
    const length = this.inputTarget.value.length
    const max = this.maxValue
    const min = this.minValue

    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${length} / ${max}`
      this.counterTarget.classList.toggle("text-red-400", length > max)
      this.counterTarget.classList.toggle("text-ink-400", length <= max)
    }

    if (this.hasSubmitTarget) {
      this.submitTarget.disabled = length < min || length > max
    }
  }

  submitOnCmd(event) {
    if ((event.metaKey || event.ctrlKey) && event.key === "Enter") {
      event.preventDefault()
      if (!this.submitTarget.disabled) {
        this.submitTarget.closest("form").requestSubmit()
      }
    }
  }
}
