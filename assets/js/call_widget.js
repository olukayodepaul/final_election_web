// assets/js/call_widget.js
//
// WhatsApp-style floating call bar, driven purely by PhoneService's
// callbacks. Renders into the #phone-widget container. Runs as plain JS,
// independent of the LiveView socket, so it survives modal closes,
// navigation, and reconnects.

const ICONS = {
  mic: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-5 h-5">
    <path d="M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z"/>
    <path d="M19 10v2a7 7 0 0 1-14 0v-2M12 19v4M8 23h8"/>
  </svg>`,
  micOff: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-5 h-5">
    <path d="M1 1l22 22"/>
    <path d="M9 9v3a3 3 0 0 0 4.5 2.6M15 9.34V4a3 3 0 0 0-5.94-.6"/>
    <path d="M17 16.95A7 7 0 0 1 5 12v-2M19 10v2c0 .93-.18 1.82-.5 2.63M12 19v4M8 23h8"/>
  </svg>`,
  video: `<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" class="w-5 h-5">
    <rect x="1" y="5" width="15" height="14" rx="2"/>
    <path d="M23 7l-7 5 7 5V7z"/>
  </svg>`,
  phoneDown: `<svg viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
    <path d="M21.99 17.5c0 .43-.25.82-.63 1L17 20.3c-.43.22-.94.15-1.3-.18l-2.87-2.6a13.4 13.4 0 0 1-6.35-6.35L3.88 8.3a1.16 1.16 0 0 1-.18-1.3l1.8-4.36c.18-.38.57-.63 1-.63h3.5c.55 0 1 .45 1 1a9.5 9.5 0 0 0 .5 3.02c.13.4.03.85-.28 1.15l-1.5 1.44a11 11 0 0 0 4.98 4.98l1.44-1.5c.3-.31.75-.41 1.15-.28a9.5 9.5 0 0 0 3.02.5c.55 0 1 .45 1 1v3.5z"/>
  </svg>`,
  phoneCheck: `<svg viewBox="0 0 24 24" fill="currentColor" class="w-6 h-6">
    <path d="M6.62 10.79a15.05 15.05 0 0 0 6.59 6.59l2.2-2.2a1 1 0 0 1 1.02-.24 11.3 11.3 0 0 0 3.54.57 1 1 0 0 1 1 1V20a1 1 0 0 1-1 1C10.16 21 3 13.84 3 5a1 1 0 0 1 1-1h3.5a1 1 0 0 1 1 1c0 1.24.2 2.44.57 3.54a1 1 0 0 1-.25 1.02l-2.2 2.2z"/>
  </svg>`
};

export class CallWidget {
  constructor(containerId = "phone-widget", audioElementId = "remote-audio") {
    this.container = document.getElementById(containerId);
    this.audioElementId = audioElementId;
    this.state = "idle"; // idle | outgoing | ringing | incoming | in_call
    this.remoteName = null;
    this.statusText = "";
    this._timerHandle = null;
    this._seconds = 0;

    if (!this.container) {
      console.error(`[CallWidget] container #${containerId} not found`);
    }
  }

  showOutgoing(name) {
    this.state = "outgoing";
    this.remoteName = name;
    this.statusText = "Calling...";
    this.render();
  }

  showRinging(name) {
    this.state = "outgoing";
    this.remoteName = name;
    this.statusText = "Ringing...";
    this.render();
  }

  showIncoming(name) {
    this.state = "incoming";
    this.remoteName = name;
    this.statusText = "Incoming call...";
    this.render();
  }

  onStatus(status) {
    if (status === "In Call") {
      this.state = "in_call";
      this.statusText = "00:00";
      this.startTimer();
      this.render();
    }
  }

  hide(_cause) {
    this.state = "idle";
    this.remoteName = null;
    this.stopTimer();
    if (this.container) {
      this.container.innerHTML = "";
      this.container.classList.add("hidden");
    }
  }

  startTimer() {
    this.stopTimer();
    this._seconds = 0;
    this._timerHandle = setInterval(() => {
      this._seconds += 1;
      const m = String(Math.floor(this._seconds / 60)).padStart(2, "0");
      const s = String(this._seconds % 60).padStart(2, "0");
      this.statusText = `${m}:${s}`;
      this.updateStatusText();
    }, 1000);
  }

  stopTimer() {
    if (this._timerHandle) {
      clearInterval(this._timerHandle);
      this._timerHandle = null;
    }
  }

  updateStatusText() {
    const el = this.container?.querySelector("[data-call-status]");
    if (el) el.textContent = this.statusText;
  }

  initials(name) {
    if (!name) return "?";
    return name
      .split(/\s+/)
      .map((p) => p[0])
      .slice(0, 2)
      .join("")
      .toUpperCase();
  }

  render() {
    if (!this.container) return;
    this.container.classList.remove("hidden");

    const isIncoming = this.state === "incoming";
    const isMuted = window.phoneService?.isMuted;

    this.container.innerHTML = `
      <div class="fixed bottom-4 left-4 z-50 w-72 rounded-2xl bg-neutral-900 text-white shadow-2xl overflow-hidden">
        <div class="flex items-center gap-3 px-4 pt-4 pb-2">
          <div class="w-11 h-11 rounded-full bg-emerald-600 flex items-center justify-center font-semibold text-sm shrink-0">
            ${this.initials(this.remoteName)}
          </div>
          <div class="min-w-0">
            <div class="font-medium truncate">${this.remoteName ?? "Unknown"}</div>
            <div class="text-sm text-neutral-400" data-call-status>${this.statusText}</div>
          </div>
        </div>

        <div class="flex items-center justify-around px-4 py-3 border-t border-neutral-800">
          ${
            isIncoming
              ? `
                <button data-action="reject"
                  class="w-11 h-11 rounded-full bg-red-600 hover:bg-red-500 flex items-center justify-center transition-colors">
                  ${ICONS.phoneDown}
                </button>
                <button data-action="answer"
                  class="w-11 h-11 rounded-full bg-emerald-600 hover:bg-emerald-500 flex items-center justify-center transition-colors">
                  ${ICONS.phoneCheck}
                </button>
              `
              : `
                <button data-action="mute"
                  class="w-10 h-10 rounded-full flex items-center justify-center transition-colors ${
                    isMuted ? "bg-white text-neutral-900" : "bg-neutral-800 hover:bg-neutral-700 text-white"
                  }">
                  ${isMuted ? ICONS.micOff : ICONS.mic}
                </button>
                <button data-action="video" disabled
                  title="Video not enabled for this call"
                  class="w-10 h-10 rounded-full bg-neutral-800 opacity-40 cursor-not-allowed flex items-center justify-center">
                  ${ICONS.video}
                </button>
                <button data-action="hangup"
                  class="w-11 h-11 rounded-full bg-red-600 hover:bg-red-500 flex items-center justify-center transition-colors">
                  ${ICONS.phoneDown}
                </button>
              `
          }
        </div>
      </div>
    `;

    this.container.querySelector('[data-action="hangup"]')?.addEventListener("click", () => {
      window.phoneService?.hangup();
    });
    this.container.querySelector('[data-action="reject"]')?.addEventListener("click", () => {
      window.phoneService?.rejectCall();
    });
    this.container.querySelector('[data-action="answer"]')?.addEventListener("click", () => {
      const audio = document.getElementById(this.audioElementId);
      window.phoneService?.answerCall(audio);
    });
    this.container.querySelector('[data-action="mute"]')?.addEventListener("click", () => {
      window.phoneService?.toggleMute();
      this.render();
    });
  }
}