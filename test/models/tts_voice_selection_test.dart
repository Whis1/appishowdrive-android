import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';

import '../fakes/fake_chat.dart';
import '../fakes/fake_tts_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('en'));

  test(
    'Twitch and Kick use Android system TTS; legacy voice packs are ignored',
    () async {
    final system = FakeTtsEngine();
    final model = TtsModel.fromJson(
      {
        'language': 'it',
        'isPreludeMuted': true,
        'speechEngine': 'supertonic-3',
        'voicePack': 'supertonic-3',
        'neuralVoices': {'it': 'F1'},
        'platformVoices': {'twitch': 'F1', 'kick': 'M1'},
      },
      engine: system,
      reportError: (error, _) => fail('$error'),
    );
    addTearDown(model.dispose);

    final l10n = lookupAppLocalizations(const Locale('it'));
    model.setMode(l10n, TtsMode.enabled);
    await pumpEventQueue();
    system.utterances.clear();

    for (final channel in [
      Channel(Providers.twitch, 'twitch', 'twitch', language: 'it'),
      Channel(Providers.kick, 'kick', 'kick', language: 'it'),
    ]) {
      final message = FakeChatMessage(
        messageId: channel.provider,
        timestamp: DateTime.now(),
        author: FakeChatUser(
          provider: channel.provider,
          userId: 'user',
          login: 'utente',
        ),
        message: 'Ciao',
      )..channel = channel;
      model.say(l10n, message);
    }

    await pumpEventQueue();
    expect(system.utterances.map((utterance) => utterance.text), ['Ciao', 'Ciao']);
    expect(system.utterances.every((utterance) => utterance.language == 'it'), isTrue);
    expect(
      system.utterances.every((utterance) => utterance.voice == null),
      isTrue,
    );
    expect(model.toJson().keys, isNot(contains('neuralVoices')));
    expect(model.toJson().keys, isNot(contains('platformVoices')));
    },
  );
}
