# APPISHOWDRIVE Android

Community edition of RealtimeChat by Muxable and its contributors.
Original source: https://github.com/muxable/rtchat, stable tag v2.11.2.
The original Apache License 2.0 and third-party notices are retained.

Changes made 7 November 2026: distinct Android identity and supplied icon;
same-phone Twitch/Kick account linking; GitHub APK updates with integrity,
package, version and signing-certificate checks; setup and audio-source help.
The native no-focus Android TTS and mixed-audio keepalive fixes are inherited
from upstream v2.11.2; this edition validates them with real Android mixed
playback tests and keeps source synchronization from reloading active pages.

This is a derivative community build, not an official Muxable release. Original
RealtimeChat services remain dependencies for account/chat features. No private
service credentials or signing keys are included. Modifications are identified
in source-file notices and the Git commit history.

## Community changes — 8 November 2026, version 1.1.0

Ten selectable interface palettes, dashboard theme, community icon sizing, per-message platform icons, offline Italian voice selection per platform, Twitch Aura controls and contextual tournament/audience/challenge flow. Manrope and Space Grotesk fonts retain their SIL Open Font License in assets/fonts/. Supertonic 3 model weights are optional downloads under OpenRAIL-M; complete license in assets/SUPERTONIC3-LICENSE.txt. No voice cloning or microphone capture is introduced.

## Community changes — 9 November 2026, version 1.1.2

Only the voice configured in Android is used. Bundled and downloadable voice models are removed, and the first launch clears their app-owned files while keeping user settings. Android TTS and WebView audio sources remain independent; TTS playback does not request audio focus. The private Sound Alerts/StreamElements overlay and physical One UI 9 / Android 17 phone were not available for direct testing. Public chat identity and badge controls, recipient-command drafting and the supplied welcome mascot remain included. The separate OBS companion in companion/obs is GPL-2.0-or-later and uses BSD-3-Clause RNNoise. The Android app does not capture another application's microphone.
