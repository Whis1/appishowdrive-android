<!-- APPISHOWDRIVE public source begins with a reviewed v2.11.2 snapshot; upstream Git history is not redistributed because older upstream commits contained service-account credentials. Original source and license remain attributed below. -->
# APPISHOWDRIVE Android

**[Download the signed Android APK](https://github.com/Whis1/appishowdrive-android/releases/latest/download/APPISHOWDRIVE-Android.apk)** · **[Guida italiana per lo streamer](GUIDA-STREAMER.md)** · [Verification](packaging/VERIFICA-ANDROID.md)

Community edition of [RealtimeChat](https://github.com/muxable/rtchat), based on stable v2.11.2. Original chat, emotes, moderation, audio sources, alerts and TTS features are retained. This is an independent community build, not an official Muxable release.

Android app identity: `com.ishowdrive.chat`. The launcher icon is the image supplied by the ISHOWDRIVE community. Twitch and Kick can be connected through Settings → Accounts; both chats are merged for TTS. Original provider services remain a dependency.

## Community update 1.1.2

- Ten selectable interface color palettes, immediately applied and saved in Settings.
- Larger, readable chat, dark dashboard theme, local Manrope/Space Grotesk fonts, compact Twitch/Kick icons at the right of each message. Original role/sub badges remain before the author.
- Only the default TTS engine configured in Android is used. Bundled neural models and downloadable voice packs are removed from the APK; the first run after updating deletes their old app-owned files while keeping accounts, chat settings and audio sources.
- Twitch badges enabled by default; public FrankerFaceZ, BetterTTV, Chatterino badges, selected Twitch pronouns and active 7TV nickname paints. History settings include per-service and all-on/off controls. One display name only, with the selected 7TV paint applied to that name. Only pure black nicknames receive the stronger contrast treatment; other colours retain their previous treatment.
- The supplied emperor welcomes signed-in users once per cold launch, with audio-aligned lips and a closed-lip smile after speech. The touch-through mascot stays at the lower left, holds for two seconds and fades. It can be disabled in Settings and does not replay on browser/page resumes.
- Aura Arena panel for Twitch, own-channel streamer actions and user commands. Command buttons show the real command names. Tournament controls appear in order: create → force choice → participation choice → start/end. Audience decisions and challenge accept/ignore controls are contextual.
- Streamer-only `!AggiungiPA N @utente` is available in the command panel and the long-press user menu. The panel fills a chat draft; the user menu uses the selected Twitch login with an amount prompt.
- User menu: immediate tagged !Processo/!Sanziona; quantity and confirmation for HP/Aura adjustments. Recipient commands in the panel, including !Sfida and !Vincites, fill the chat draft for manual completion and sending.
- Launcher icon fills its Android mask. Preview defaults to HD Auto and retains a manual quality choice.

The app cannot filter the microphone captured by another Android app. An optional [OBS Windows companion](https://github.com/Whis1/appishowdrive-android/releases/latest/download/APPISHOWDRIVE-Voce-OBS.zip) applies adaptive voice/noise processing to the selected dedicated mic source on the receiving PC. It restores ambience between speech, and must not be applied to mixed music/alerts/TTS. Installation and source selection on the streamer's PC are required; its private phone-to-OBS feed has not been tested. Companion code is GPL-2.0-or-later with BSD-licensed RNNoise, separate from the Android APK. The manual fighting arena is not included.

Updates are distributed through this repository’s GitHub Releases. The app checks at launch, downloads new APKs with progress and verifies size, SHA256, package, increasing version and the installed app’s signing certificate. Android confirmation is required to install. APK installation restarts the app: install at the end of the live. User settings and accounts are preserved across updates to this app.

Android system TTS playback does not request audio focus or issue pause commands to the app's independent WebView audio sources. Controlled audio/video tests are provided in `integration_test/appishowdrive_audio_test.dart`. The streamer's private Sound Alerts/StreamElements overlay and physical One UI 9 / Android 17 phone were unavailable for direct reproduction.

See [community notices](NOTICE-APPISHOWDRIVE.md) and the original [Apache-2.0 license](LICENSE). Upstream deployment workflows are preserved disabled so this fork cannot deploy to the original provider’s infrastructure.

---

Original upstream documentation:

# RealtimeChat

A chat app for IRL streamers.

<a href='https://play.google.com/store/apps/details?id=com.rtirl.chat&pcampaignid=pcampaignidMKT-Other-global-all-co-prtnr-py-PartBadge-Mar2515-1'><img alt='Get it on Google Play' height="85" src='./assets/google-play-badge.png'/></a>
<a href="https://apps.apple.com/app/id1567720948"><img alt='Download on the App Store' height="85" src="./assets/apple-download.svg"></a>

## Getting Started

RealtimeChat is a standard Flutter application. We support Android and iOS but not web. To get started, follow the standard

```
flutter pub get
flutter run
```

If this is your first exposure to Flutter, follow the [install guide](https://flutter.dev/docs/get-started/install) to set up your environment. Optionally, go through the [codelab](https://flutter.dev/docs/get-started/codelab) to learn how Flutter applications are written.

## Testing

Unit and widget tests run with `flutter test`.

End-to-end tests in `integration_test/app_test.dart` run the full app against the Firebase emulator suite on an Android emulator or device:

```
npx firebase-tools emulators:exec --only auth,firestore,database --project rtchat-47692 \
  "flutter test integration_test/app_test.dart"
```

The other files in `integration_test/` are on-device text-to-speech tests that need a downloaded model; see `packages/on_device_tts/README.md`.

## Contributing

Communication is done through [our Discord server](https://discord.gg/UKHJMQs74u). Come by and say hi! Otherwise, feel free to browse our issues list for contribution ideas.

Never contributed to open source before? All levels of experience are welcome! We're happy to help mentor you even if this is your first open source contribution. You must, however, have knowledge about what IRL streaming is and at least watch a few IRL streamers to understand the use case for a chat app like this. Stop by the Discord and ask for muxfd.

## YouTube support?

Adding YouTube support is possible but requires a decent amount of work. If you are open to contributing, please reach out!

## Translations

Translations live in `lib/l10n/app_<locale>.arb`, with `app_en.arb` as the template. Every locale must provide a nonempty translation for each template message. CI checks for missing or blank translations.
