import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/migrations/legacy_voice_cleanup.dart';

void main() {
  test('removes only legacy TTS model folders', () async {
    final root = await Directory.systemTemp.createTemp('appishowdrive-tts-');
    addTearDown(() => root.delete(recursive: true));
    final oldPack = File('${root.path}/voice_packs/packs/supertonic-3/model');
    final oldSpeech = File('${root.path}/speech/kokoro.litertlm');
    final settings = File('${root.path}/user/settings.json');
    await oldPack.create(recursive: true);
    await oldSpeech.create(recursive: true);
    await settings.create(recursive: true);

    await clearLegacyVoiceModelData(root);

    expect(await Directory('${root.path}/voice_packs').exists(), isFalse);
    expect(await Directory('${root.path}/speech').exists(), isFalse);
    expect(await settings.exists(), isTrue);
  });
}
