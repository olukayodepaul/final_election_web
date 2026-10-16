// assets/js/hooks/voice_recorder.js
//
// Usage in app.js:
//   import VoiceRecorder from "./hooks/voice_recorder"
//   let Hooks = { ChatScroll, SipCredentials, VoiceRecorder, ... }
//   new LiveSocket("/live", Socket, { hooks: Hooks, ... })
//
// Expects (rendered by LiveModal):
//   [data-idle] [data-mic]                      text row + mic button
//   [data-recording] [data-trash] [data-dot] [data-timer]
//                    [data-pause] [data-icon-pause] [data-icon-play]
//                    [data-send-voice]          recording row
//   and a LiveView upload named "voice" (hidden live_file_input).

const VoiceRecorder = {
  mounted() {
    this.state = "idle"; // idle | recording | paused
    this.secs = 0;
    this.chunks = [];
    this.send = false;
    this.rec = null;
    this.stream = null;
    this.timer = null;

    // Delegated, so LiveView patches that replace inner nodes can't drop the listeners.
    this.el.addEventListener("click", (e) => {
      if (e.target.closest("[data-mic]")) this.start();
      else if (e.target.closest("[data-trash]")) this.stop(false);
      else if (e.target.closest("[data-pause]")) this.togglePause();
      else if (e.target.closest("[data-send-voice]")) this.stop(true);
    });

    this.paint();
  },

  // LiveView re-renders (new chat message, etc.) must not reset the recording UI.
  updated() {
    this.paint();
  },

  // Modal closed or Esc pressed: discard and release the microphone.
  destroyed() {
    this.stop(false);
  },

  async start() {
    if (this.state !== "idle") return;

    if (!navigator.mediaDevices || !window.MediaRecorder) {
      alert("Voice recording is not supported in this browser (HTTPS is required).");
      return;
    }

    try {
      this.stream = await navigator.mediaDevices.getUserMedia({ audio: true });
    } catch (_err) {
      alert("Microphone access was denied.");
      return;
    }

    // Prefer mp4/AAC (plays on iOS and Android), fall back to webm/ogg.
    const mime = ["audio/mp4", "audio/webm;codecs=opus", "audio/webm", "audio/ogg;codecs=opus"].find(
      (t) => MediaRecorder.isTypeSupported(t)
    );

    this.rec = new MediaRecorder(this.stream, mime ? { mimeType: mime } : {});
    this.chunks = [];
    this.send = false;
    this.secs = 0;

    this.rec.ondataavailable = (e) => {
      if (e.data && e.data.size > 0) this.chunks.push(e.data);
    };
    this.rec.onstop = () => this.finish();
    this.rec.start(250);

    this.state = "recording";
    this.timer = setInterval(() => {
      if (this.state === "recording") {
        this.secs += 1;
        this.paint();
      }
    }, 1000);

    this.paint();
  },

  togglePause() {
    if (!this.rec) return;

    if (this.state === "recording") {
      this.rec.pause();
      this.state = "paused";
    } else if (this.state === "paused") {
      this.rec.resume();
      this.state = "recording";
    }

    this.paint();
  },

  // send = true -> upload the recording, false -> throw it away.
  stop(send) {
    if (!this.rec) return;

    this.send = send && this.secs >= 1; // ignore accidental taps
    clearInterval(this.timer);

    if (this.rec.state !== "inactive") this.rec.stop();
    else this.finish();

    if (this.stream) this.stream.getTracks().forEach((t) => t.stop());
    this.stream = null;

    this.state = "idle";
    this.paint();
  },

  finish() {
    const chunks = this.chunks;
    const rec = this.rec;
    this.rec = null;
    this.chunks = [];

    if (!this.send || chunks.length === 0) return;

    const type = ((rec && rec.mimeType) || "audio/webm").split(";")[0];
    const ext = type.includes("mp4") ? "m4a" : type.includes("ogg") ? "ogg" : "webm";
    const file = new File([new Blob(chunks, { type })], `voice-${Date.now()}.${ext}`, { type });

    // Goes through the hidden live_file_input; the server delivers it when the upload completes.
    this.upload("voice", [file]);
  },

  paint() {
    const active = this.state !== "idle";
    const paused = this.state === "paused";

    this.el.querySelector("[data-idle]").classList.toggle("hidden", active);
    this.el.querySelector("[data-recording]").classList.toggle("hidden", !active);

    const m = Math.floor(this.secs / 60);
    const s = String(this.secs % 60).padStart(2, "0");
    this.el.querySelector("[data-timer]").textContent = `${m}:${s}`;

    this.el.querySelector("[data-icon-pause]").classList.toggle("hidden", paused);
    this.el.querySelector("[data-icon-play]").classList.toggle("hidden", !paused);
    this.el.querySelector("[data-dot]").classList.toggle("animate-pulse", !paused);
  },
};

export default VoiceRecorder;