import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    delay: { type: Number, default: 5000 },
  };

  connect() {
    this.boundDismiss = this.dismiss.bind(this);

    if (!this.element.dataset.dismissAt) {
      this.element.dataset.dismissAt = String(Date.now() + this.delayValue);
    }

    this.#schedule();
    document.addEventListener("turbo:before-cache", this.boundDismiss);
  }

  disconnect() {
    this.#clearTimer();
    document.removeEventListener("turbo:before-cache", this.boundDismiss);
  }

  dismiss() {
    this.#clearTimer();
    document.removeEventListener("turbo:before-cache", this.boundDismiss);

    const toast = this.element.parentElement;
    this.element.remove();

    if (toast?.classList.contains("toast") && toast.children.length === 0) {
      toast.remove();
    }
  }

  #schedule() {
    this.#clearTimer();
    const remaining = Number(this.element.dataset.dismissAt) - Date.now();
    this.timeout = setTimeout(() => this.dismiss(), Math.max(0, remaining));
  }

  #clearTimer() {
    clearTimeout(this.timeout);
  }
}
