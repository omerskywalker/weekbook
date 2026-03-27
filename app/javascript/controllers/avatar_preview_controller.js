import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preview"]

  show(event) {
    const file = event.target.files[0]
    if (!file) return
    this.previewTarget.src = URL.createObjectURL(file)
    this.previewTarget.classList.remove("hidden")
    const initials = document.getElementById("avatar-initials")
    if (initials) initials.classList.add("hidden")
  }
}
