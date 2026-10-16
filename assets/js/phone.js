// assets/js/phone.js
//
// JsSIP-based PhoneService. Extension = user_id, password = shared secret
// for now (per mount.ex TODO). Public API:
//   new PhoneService({ domain, wsPort, wssPort, useSecure, extension, password,
//                       onStatusChange, onIncomingCall, onOutgoingCall,
//                       onCallProgress, onCallEnded })
//   .init()                                            -> Promise
//   .makeCall(targetExtension, remoteAudioEl, name?)
//   .answerCall(remoteAudioEl)
//   .rejectCall()
//   .hangup()
//   .toggleMute()                                      -> returns new isMuted

import JsSIP from "jssip";

export class PhoneService {
  constructor(config = {}) {
    this.domain = config.domain || "104.248.174.227";
    this.wsPort = config.wsPort || 54325;
    this.wssPort = config.wssPort || 54324;
    this.useSecure = config.useSecure ?? (window.location.protocol === "https:");

    this.extension = config.extension || "2001";
    this.password = config.password || "testpass123";

    const scheme = this.useSecure ? "wss" : "ws";
    const port = this.useSecure ? this.wssPort : this.wsPort;
    this.serverUrl = `${scheme}://${this.domain}:${port}`;

    this.iceServers = config.iceServers || [
      {
        urls: "turn:104.248.174.227:54322?transport=udp",
        username: "voiceapp",
        credential: "@admin!ele"
      }
    ];

    this.ua = null;
    this.currentSession = null;
    this.isMuted = false;
    this.remoteName = null;

    this.onStatusChange = config.onStatusChange || (() => {});
    this.onIncomingCall = config.onIncomingCall || (() => {});
    this.onOutgoingCall = config.onOutgoingCall || (() => {});
    this.onCallProgress = config.onCallProgress || (() => {});
    this.onCallEnded = config.onCallEnded || (() => {});
  }

  init() {
    return new Promise((resolve, reject) => {
      try {
        JsSIP.debug.disable("JsSIP:*");

        const socket = new JsSIP.WebSocketInterface(this.serverUrl);

        this.ua = new JsSIP.UA({
          sockets: [socket],
          uri: `sip:${this.extension}@${this.domain}`,
          authorization_user: this.extension,
          password: this.password,
          register: true,
          session_timers: false
        });

        this.ua.on("connecting", () => {
          console.log("[JsSIP] Connecting to", this.serverUrl);
          this.onStatusChange("Connecting...");
        });

        this.ua.on("connected", () => {
          console.log("[JsSIP] WebSocket connected");
        });

        this.ua.on("disconnected", (e) => {
          console.warn("[JsSIP] WebSocket disconnected:", e);
          this.onStatusChange("Disconnected");
        });

        this.ua.on("registered", () => {
          console.log(`[JsSIP] Registered as ${this.extension} on ${this.serverUrl}`);
          this.onStatusChange("Registered");
          resolve();
        });

        this.ua.on("unregistered", (e) => {
          console.warn("[JsSIP] Unregistered:", e);
          this.onStatusChange("Unregistered");
        });

        this.ua.on("registrationFailed", (e) => {
          const status = e.response?.status_code;
          const reason = e.response?.reason_phrase;
          console.error(
            `[JsSIP] Registration FAILED - cause: ${e.cause}` +
              (status ? `, SIP status: ${status} ${reason}` : "")
          );
          this.onStatusChange(`Registration Failed: ${e.cause}`);
          reject(new Error(`SIP registration failed: ${e.cause}`));
        });

        this.ua.on("newRTCSession", (data) => {
          if (data.originator === "remote") {
            this.handleIncomingCall(data.session);
          }
        });

        this.ua.start();
      } catch (err) {
        console.error("[JsSIP] init() threw:", err);
        this.onStatusChange("Init Error");
        reject(err);
      }
    });
  }

  handleIncomingCall(session) {
    this.currentSession = session;
    this.isMuted = false;
    this.remoteName =
      session.remote_identity.display_name || session.remote_identity.uri.user || "Unknown";

    session.on("ended", (e) => {
      this.cleanupSession();
      this.onCallEnded(e.cause);
    });

    session.on("failed", (e) => {
      this.cleanupSession();
      this.onCallEnded(e.cause);
    });

    this.onIncomingCall(this.remoteName);
  }

  answerCall(remoteAudioElement) {
    if (!this.currentSession) return;

    this.currentSession.on("confirmed", () => {
      this.bindRemoteAudio(this.currentSession, remoteAudioElement);
      this.onStatusChange("In Call");
    });

    this.currentSession.answer({
      mediaConstraints: { audio: true, video: false },
      pcConfig: { iceServers: this.iceServers }
    });
  }

  makeCall(targetExtension, remoteAudioElement, displayName = null) {
    if (!this.ua || !this.ua.isRegistered()) {
      console.error("[JsSIP] Cannot call - UA not registered yet");
      this.onStatusChange("Not registered - cannot call");
      return;
    }

    this.isMuted = false;
    this.remoteName = displayName || targetExtension;

    const target = `sip:${targetExtension}@${this.domain}`;
    const session = this.ua.call(target, {
      mediaConstraints: { audio: true, video: false },
      pcConfig: { iceServers: this.iceServers }
    });

    this.currentSession = session;
    this.onOutgoingCall(this.remoteName);

    session.on("progress", () => {
      this.onStatusChange("Ringing...");
      this.onCallProgress(this.remoteName);
    });

    session.on("confirmed", () => {
      this.bindRemoteAudio(session, remoteAudioElement);
      this.onStatusChange("In Call");
    });

    session.on("ended", (e) => {
      this.cleanupSession();
      this.onCallEnded(e.cause);
    });

    session.on("failed", (e) => {
      console.error("[JsSIP] Call failed:", e.cause);
      this.cleanupSession();
      this.onCallEnded(e.cause);
    });
  }

  bindRemoteAudio(session, remoteAudioElement) {
    const pc = session.connection;
    if (!pc || !remoteAudioElement) return;

    const remoteStream = new MediaStream();
    pc.getReceivers().forEach((receiver) => {
      if (receiver.track) remoteStream.addTrack(receiver.track);
    });

    remoteAudioElement.srcObject = remoteStream;
    remoteAudioElement.play().catch((err) =>
      console.error("[JsSIP] Audio playback error:", err)
    );
  }

  toggleMute() {
    if (!this.currentSession) return this.isMuted;

    if (this.isMuted) {
      this.currentSession.unmute({ audio: true });
    } else {
      this.currentSession.mute({ audio: true });
    }

    this.isMuted = !this.isMuted;
    return this.isMuted;
  }

  rejectCall() {
    if (this.currentSession) {
      this.currentSession.terminate();
      this.cleanupSession();
    }
  }

  hangup() {
    if (this.currentSession) {
      this.currentSession.terminate();
      this.cleanupSession();
    }
  }

  cleanupSession() {
    this.currentSession = null;
    this.remoteName = null;
    this.isMuted = false;
    this.onStatusChange("Registered");
  }
}