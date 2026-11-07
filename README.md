<!-- APPISHOWDRIVE public source begins with a reviewed v2.11.2 snapshot; upstream Git history is not redistributed because older upstream commits contained service-account credentials. Original source and license remain attributed below. -->
# APPISHOWDRIVE Android

**[Download the signed Android APK](https://github.com/Whis1/appishowdrive-android/releases/latest/download/APPISHOWDRIVE-Android.apk)** · **[Guida italiana per lo streamer](GUIDA-STREAMER.md)** · [Verification](packaging/VERIFICA-ANDROID.md)

Community edition of [RealtimeChat](https://github.com/muxable/rtchat), based on stable v2.11.2. Original chat, emotes, moderation, audio sources, alerts and TTS features are retained. This is an independent community build, not an official Muxable release.

Android app identity: `com.ishowdrive.chat`. The launcher icon is the image supplied by the ISHOWDRIVE community. Twitch and Kick can be connected through Settings → Accounts; both chats are merged for TTS. Original provider services remain a dependency.

Updates are distributed through this repository’s GitHub Releases. The app checks at launch, downloads new APKs with progress and verifies size, SHA256, package, increasing version and the installed app’s signing certificate. Android confirmation is required to install. APK installation restarts the app: install at the end of the live. User settings and accounts are preserved across updates to this app.

The upstream Android native system-speech and speaker keep-alive mixing fixes are included. Controlled Android video/speech tests are provided in `integration_test/appishowdrive_audio_test.dart`; they do not use or trigger a streamer’s private Sound Alerts URL.

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
