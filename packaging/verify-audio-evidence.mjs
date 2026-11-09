import fs from 'node:fs';
import path from 'node:path';
import {createHash} from 'node:crypto';
import assert from 'node:assert/strict';

export const AUDIO_SOURCE_FILES = [
  'pubspec.yaml', 'pubspec.lock',
  'lib/main.dart', 'lib/models/tts.dart', 'lib/audio_channel.dart',
  'lib/speaker_keep_alive.dart', 'lib/components/welcome_mascot.dart',
  'packages/on_device_tts/lib/src/system_tts_engine.dart',
  'packages/on_device_tts/lib/src/system_tts_platform.dart',
  'packages/on_device_tts/android/build.gradle.kts',
  'packages/on_device_tts/android/src/main/kotlin/com/muxable/ondevicetts/SystemTtsPlugin.kt',
  'packages/on_device_tts/android/src/main/kotlin/com/muxable/ondevicetts/OnDeviceTtsPlugin.kt',
  'android/app/build.gradle', 'android/app/proguard-rules.pro',
  'android/app/src/main/AndroidManifest.xml',
  'android/app/src/main/kotlin/com/rtirl/chat/AudioService.kt',
  'android/app/src/main/kotlin/com/rtirl/chat/TtsService.kt',
  'android/app/src/main/kotlin/com/rtirl/chat/MainActivity.kt',
  'integration_test/appishowdrive_audio_test.dart',
  'integration_test/fixtures/audio_mix_video.dart',
];

export const sha256 = bytes => createHash('sha256').update(bytes).digest('hex');

export function audioSourceFingerprint(root) {
  const hash = createHash('sha256');
  for (const file of AUDIO_SOURCE_FILES) {
    hash.update(file + '\0');
    hash.update(fs.readFileSync(path.join(root, file)));
    hash.update('\0');
  }
  return hash.digest('hex');
}

// A passing report from an older app is not evidence for the current sources.
export function assertVerifiedAndroidAudio(root, verification) {
  const evidence = verification.audioEvidence;
  assert.equal(evidence?.schema, 1, 'Fresh audio evidence with source identity is required');
  const fingerprint = audioSourceFingerprint(root);
  assert.equal(evidence.sourceSha256, fingerprint, 'Audio test sources changed; rerun the emulator test');
  const bytes = fs.readFileSync(path.join(root, 'qa-artifacts/audio-continuity-report.json'));
  assert.equal(evidence.reportSha256, sha256(bytes), 'Audio report changed after verification');
  const report = JSON.parse(bytes);
  assert.equal(report.sourceSha256, fingerprint, 'Audio report belongs to different sources');
  assert.equal(report.passed, true, 'Audio continuity measurement did not pass');
  assert.equal(report.scene.realAndroid, true, 'A real Android emulator/device run is required');
  assert.ok(report.scene.speechEndAt > report.scene.speechStartAt);
  assert.equal(report.scene.videoPausedDuringSpeech, false);
  assert.ok(report.duringSpeech.windows > 20);
  assert.ok(report.duringSpeech.pilotPresentFraction > 0.95);
  assert.ok(report.duringSpeech.longestPilotGapMs < 180);
  return report;
}
