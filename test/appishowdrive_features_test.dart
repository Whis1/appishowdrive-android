import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:rtchat/models/aura_arena.dart';
import 'package:rtchat/models/channels.dart';
import 'fakes/fake_chat.dart';

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
      expect(
        auraEncode(c('!AggiungiPA'), target: 'Bob', amount: '200'),
        '!AggiungiPA 200 @bob',
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

}
