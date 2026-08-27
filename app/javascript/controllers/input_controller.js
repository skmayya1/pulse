import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 250 },
  };

  submit() {
    this.#clearTimer();
    this.timeout = setTimeout(() => this.#submitForm(), this.delayValue);
  }

  submitNow() {
    this.#clearTimer();
    this.#submitForm();
  }

  disconnect() {
    this.#clearTimer();
  }

  #submitForm() {
    this.element.form?.requestSubmit();
  }

  #clearTimer() {
    clearTimeout(this.timeout);
  }
}
