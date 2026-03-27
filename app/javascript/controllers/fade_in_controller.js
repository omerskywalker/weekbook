import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    if (!("IntersectionObserver" in window)) {
      this.element.classList.remove("opacity-0")
      return
    }

    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            entry.target.classList.add("animate-fade-in")
            entry.target.classList.remove("opacity-0")
            observer.unobserve(entry.target)
          }
        })
      },
      { threshold: 0.08 }
    )

    observer.observe(this.element)
  }
}
