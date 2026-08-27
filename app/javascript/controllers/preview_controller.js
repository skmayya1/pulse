import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "list"];
  static values = { max: { type: Number, default: 5 } };

  connect() {
    this.urls = [];
  }

  show() {
    this.#revoke();
    this.listTarget.replaceChildren();
    for (const file of this.#limitedFiles()) {
      this.listTarget.append(this.#thumbnail(file));
    }
  }

  disconnect() {
    this.#revoke();
  }

  #limitedFiles() {
    const files = Array.from(this.inputTarget.files).slice(0, this.maxValue);
    if (this.inputTarget.files.length > this.maxValue) {
      const transfer = new DataTransfer();
      for (const file of files) {
        transfer.items.add(file);
      }
      this.inputTarget.files = transfer.files;
    }
    return files;
  }

  #thumbnail(file) {
    const url = URL.createObjectURL(file);
    this.urls.push(url);

    const preview = file.type.startsWith("video/")
      ? document.createElement("video")
      : document.createElement("img");
    preview.src = url;
    preview.className = "size-24 rounded-box object-cover";

    if (preview instanceof HTMLVideoElement) {
      preview.muted = true;
      preview.playsInline = true;
      preview.setAttribute("aria-label", file.name);
    } else {
      preview.alt = file.name;
    }

    return preview;
  }

  #revoke() {
    for (const url of this.urls) {
      URL.revokeObjectURL(url);
    }
    this.urls = [];
  }
}
