import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/aura_arena.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/messages/message.dart';
import 'package:rtchat/models/tts.dart';
import 'fakes/fake_chat.dart';
import 'fakes/fake_tts_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => initializeDateFormatting('it'));
  final channel = Channel(Providers.twitch, '42', 'Streamer');
  final kick = Channel(Providers.kick, '42', 'Streamer');
  test(
    'Aura: comandi canonici, nome e importo al posto corretto, nessuna iniezione',
    () {
      AuraCommand c(String code) =>
          auraStreamerCommands.firstWhere((c) => c.command == code);
      expect(
        auraEncode(c('!HP'), target: '@Alice', amount: '0080'),
        '!HP 80 @alice',
      );
      expect(
        auraEncode(c('!LevaHP'), target: 'Bob', amount: '74'),
        '!LevaHP 74 @bob',
      );
      expect(
        auraEncode(c('!LevaPA'), target: 'Bob', amount: '200'),
        '!LevaPA 200 @bob',
      );
      expect(auraEncode(c('!Processo'), target: 'Alice'), '!Processo @alice');
      expect(auraEncode(c('!Sanziona'), target: 'Bob'), '!Sanziona @bob');
      for (final target in ['', 'a b', 'alice\n!Wipe', '@@Alice']) {
        expect(
          () => auraEncode(c('!Processo'), target: target),
          throwsArgumentError,
        );
      }
      for (final amount in ['', '-1', '0', '2.5', '10 !Wipe', '10001']) {
        expect(
          () => auraEncode(c('!HP'), target: 'alice', amount: amount),
          throwsArgumentError,
        );
      }
      expect(auraStreamerCommands.any((c) => c.command == '!Sfida1'), isFalse);
      expect(auraUserCommands.any((c) => c.command == '!Ruotas'), isTrue);
    },
  );
  test('Aura: udienze e torneo cambiano solo nel proprio stato di canale', () {
    final model = AuraArenaModel();
    addTearDown(model.dispose);
    model.sent(channel, '!Apriudienze');
    expect(model.state(channel).audiences, isTrue);
    expect(model.state(kick).audiences, isFalse);
    model.sent(channel, '!Chiudiudienze');
    expect(model.state(channel).audiences, isFalse);
    model.sent(channel, '!Creatorneo');
    expect(model.state(channel).tournament, 1);
    model.withoutForce(channel);
    expect(model.state(channel).tournament, 2);
    model.skipParticipation(channel);
    expect(model.state(channel).tournament, 3);
    model.sent(channel, '!Terminatorneo');
    expect(model.state(channel).tournament, 0);
    model.sent(channel, '!Creatorneo');
    model.sent(channel, '!ForzaTorneo');
    expect(model.state(channel).tournament, 2);
    model.sent(channel, '!Partecipatorneo');
    expect(model.state(channel).tournament, 3);
    model.sent(channel, '!Iniziatorneo');
    expect(model.state(channel).tournament, 0);
  });
  test(
    'Aura: inviti solo dal bot Twitch, nome destinatario corretto e scadenza assoluta',
    () {
      var now = DateTime.utc(2026, 11, 8, 12);
      final model = AuraArenaModel(clock: () => now);
      addTearDown(model.dispose);
      FakeChatMessage bot(String login, {DateTime? at}) => FakeChatMessage(
        messageId: 'm',
        timestamp: at ?? now,
        author: FakeChatUser(
          provider: Providers.twitch,
          userId: 'bot',
          login: login,
        ),
        message: '@Streamer, Alice ti sfida! Scrivi !accetta entro 1 minuto.',
      );
      model.observe(channel, bot('viewer'), recipient: 'Streamer');
      expect(model.invitation(channel), isNull);
      model.observe(kick, bot('ufonibiru'), recipient: 'Streamer');
      expect(model.invitation(kick), isNull);
      model.observe(
        channel,
        bot('ufonibiru', at: now.subtract(const Duration(minutes: 2))),
        recipient: 'Streamer',
      );
      expect(model.invitation(channel), isNull);
      model.observe(channel, bot('ufonibiru'), recipient: 'Streamer');
      expect(
        model.invitation(channel, recipient: 'Streamer')!.challenger,
        'Alice',
      );
      expect(model.invitation(channel, recipient: 'Other'), isNull);
      now = now.add(const Duration(minutes: 1));
      expect(model.invitation(channel), isNull);
    },
  );
  test(
    'Aura: ignorare non invia comandi e accettare elimina gli inviti locali',
    () {
      final now = DateTime.now(), model = AuraArenaModel();
      addTearDown(model.dispose);
      final message = FakeChatMessage(
        messageId: 'm',
        timestamp: now,
        author: const FakeChatUser(
          provider: Providers.twitch,
          userId: 'b',
          login: 'ufonibiru',
        ),
        message: '@Streamer, Alice ti sfida! Scrivi !accetta entro 1 minuto.',
      );
      model.observe(channel, message, recipient: 'Streamer');
      model.dismiss(channel);
      expect(model.invitation(channel), isNull);
      model.observe(channel, message, recipient: 'Streamer');
      model.sent(channel, '!Accetta @alice');
      expect(model.invitation(channel), isNull);
    },
  );

  test(
    'TTS: voci diverse Twitch/Kick, italiano esplicito e preferenze conservate',
    () async {
      final system = FakeTtsEngine(),
          neural = FakeTtsEngine(
            availableVoices: const [
              TtsVoice(id: 'F1', name: 'F1', locale: 'it'),
              TtsVoice(id: 'M1', name: 'M1', locale: 'it'),
            ],
          );
      final tts = TtsModel.fromJson(
        {'language': 'en', 'isPreludeMuted': true},
        engine: system,
        reportError: (e, _) => fail('$e'),
      )..neuralEngine = neural;
      addTearDown(tts.dispose);
      tts.setPlatformVoice('twitch', 'F1');
      tts.setPlatformVoice('kick', 'M1');
      final l10n = lookupAppLocalizations(const Locale('it'));
      tts.setMode(l10n, TtsMode.enabled);
      await pumpEventQueue();
      neural.utterances.clear();
      system.utterances.clear();
      for (final c in [channel, kick]) {
        final m = FakeChatMessage(
          messageId: c.provider,
          timestamp: DateTime.now(),
          author: FakeChatUser(
            provider: c.provider,
            userId: 'u',
            login: 'utente',
          ),
          message: 'Ciao, come state?',
        )..channel = c;
        tts.say(l10n, m);
      }
      await pumpEventQueue();
      expect(neural.utterances.map((u) => u.voice?.id), ['F1', 'M1']);
      expect(neural.utterances.every((u) => u.language == 'it'), isTrue);
      expect(system.spoken, isEmpty);
      final restored = TtsModel.fromJson(tts.toJson(), engine: FakeTtsEngine());
      addTearDown(restored.dispose);
      expect(restored.platformVoice('twitch'), 'F1');
      expect(restored.platformVoice('kick'), 'M1');
      tts.setPlatformVoice('kick', 'F1');
      expect(tts.platformVoice('kick'), tts.platformVoice('twitch'));
      expect(() => tts.setPlatformVoice('bad', 'F1'), throwsArgumentError);
      expect(
        () => tts.setPlatformVoice('kick', 'unknown'),
        throwsArgumentError,
      );
    },
  );
  test(
    'TTS: voce Android per una piattaforma, IA per l’altra, senza cambiare la lingua delle altre chat',
    () async {
      final system = FakeTtsEngine(),
          neural = FakeTtsEngine(
            availableVoices: const [
              TtsVoice(id: 'F1', name: 'F1', locale: 'it'),
            ],
          );
      final tts = TtsModel.fromJson(
        {
          'language': 'en',
          'isPreludeMuted': true,
          'platformVoices': {'twitch': 'F1', 'kick': 'system'},
        },
        engine: system,
        reportError: (e, _) => fail('$e'),
      )..neuralEngine = neural;
      addTearDown(tts.dispose);
      final l10n = lookupAppLocalizations(const Locale('it'));
      tts.setMode(l10n, TtsMode.enabled);
      await pumpEventQueue();
      system.utterances.clear();
      neural.utterances.clear();
      final m = FakeChatMessage(
        messageId: 'kick',
        timestamp: DateTime.now(),
        author: const FakeChatUser(
          provider: 'kick',
          userId: 'u',
          login: 'utente',
        ),
        message: 'Ciao Kick',
      )..channel = kick;
      tts.say(l10n, m);
      await pumpEventQueue();
      expect(system.utterances.single.language, 'it');
      expect(neural.spoken, isEmpty);
      expect(tts.platformVoice('twitch'), 'F1');
    },
  );
}
