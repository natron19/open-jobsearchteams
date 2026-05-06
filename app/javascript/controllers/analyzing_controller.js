import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "overlay"]

  submit() {
    this.formTarget.classList.add("d-none")
    this.overlayTarget.classList.remove("d-none")
  }
}
