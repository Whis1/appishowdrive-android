import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/components/aura_controls.dart';
import 'package:rtchat/models/aura_arena.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/commands.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/themes.dart';
import '../fakes/fake_api.dart';
import '../fakes/fake_user_model.dart';

void main() {
  final channel = Channel(Providers.twitch, '42', 'Streamer');
  tearDown(Api.debugReset);
  Widget app(AuraArenaModel model, UserModel user, Widget child) =>
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuraArenaModel>.value(value: model),
          ChangeNotifierProvider<UserModel>.value(value: user),
          ChangeNotifierProvider(create: (_) => CommandsModel.fromJson({})),
          ChangeNotifierProvider(create: (_) => LayoutModel.fromJson({})),
        ],
        child: MaterialApp(
          theme: Themes.darkTheme,
          home: Scaffold(body: child),
        ),
      );

  testWidgets(
    'Aura: quattro decisioni durante udienze e ripristino comandi dopo chiusura',
    (tester) async {
      final model = AuraArenaModel(),
          user = FakeUserModel(userChannel: channel);
      addTearDown(model.dispose);
      addTearDown(user.dispose);
      final api = fakeApiFor(user.accounts.single);
      await tester.pumpWidget(
        app(model, user, AuraCommandPanel(channel: channel)),
      );
      expect(find.text('Comandi Aura'), findsOneWidget);
      expect(find.text('Solo Streamer'), findsOneWidget);
      expect(find.text('Solo utenti'), findsOneWidget);
      for (final command in [
        '!Iniziatorneo',
        '!Terminatorneo',
        '!ForzaTorneo',
      ]) {
        expect(find.text(command), findsNothing);
      }
      expect(find.textContaining('Iscrivi dalla chat'), findsNothing);
      await tester.tap(find.text('!Apriudienze'));
      await tester.pumpAndSettle();
      expect(api.calls.single.data['message'], '!Apriudienze');
      for (final text in [
        '!Chiudiudienze',
        '!Approva',
        '!Rifiuta',
        '!Arresta',
      ]) {
        expect(find.text(text), findsOneWidget);
      }
      expect(find.text('!Creatorneo'), findsNothing);
      await tester.tap(find.text('!Chiudiudienze'));
      await tester.pumpAndSettle();
      expect(api.calls.last.data['message'], '!Chiudiudienze');
      expect(find.text('!Apriudienze'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Aura: un altro utente vede solo i propri comandi, senza invii amministrativi',
    (tester) async {
      final model = AuraArenaModel(),
          user = FakeUserModel(
            userChannel: Channel(Providers.twitch, 'other', 'Other'),
          );
      addTearDown(model.dispose);
      addTearDown(user.dispose);
      final api = fakeApiFor(user.accounts.single);
      await tester.pumpWidget(
        app(model, user, AuraCommandPanel(channel: channel)),
      );
      expect(find.text('!Apriudienze'), findsNothing);
      await tester.tap(find.text('Solo utenti'));
      await tester.pumpAndSettle();
      expect(find.text('!Sfida'), findsOneWidget);
      final context = tester.element(find.byType(AuraCommandPanel));
      expect(
        await sendAura(context, channel, auraStreamerCommands.first),
        isFalse,
      );
      expect(api.calls, isEmpty);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Aura: processo invia subito con il tag; HP richiede numero e spunta',
    (tester) async {
      final model = AuraArenaModel(),
          user = FakeUserModel(userChannel: channel);
      addTearDown(model.dispose);
      addTearDown(user.dispose);
      final api = fakeApiFor(user.accounts.single);
      await tester.pumpWidget(
        app(
          model,
          user,
          Builder(
            builder:
                (context) => Column(
                  children: [
                    TextButton(
                      onPressed:
                          () => runAuraCommand(
                            context,
                            channel,
                            auraStreamerCommands.firstWhere(
                              (c) => c.command == '!Processo',
                            ),
                            target: 'Alice',
                          ),
                      child: const Text('Processo target'),
                    ),
                    TextButton(
                      onPressed:
                          () => runAuraCommand(
                            context,
                            channel,
                            auraStreamerCommands.firstWhere(
                              (c) => c.command == '!HP',
                            ),
                            target: 'Alice',
                          ),
                      child: const Text('HP target'),
                    ),
                  ],
                ),
          ),
        ),
      );
      await tester.tap(find.text('Processo target'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(api.calls.single.data['message'], '!Processo @alice');
      await tester.tap(find.text('HP target'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      await tester.enterText(find.byType(TextField).last, '80');
      await tester.tap(find.text('Invia'));
      await tester.pumpAndSettle();
      expect(api.calls.last.data['message'], '!HP 80 @alice');
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Aura: torneo con scelta partecipazione e controlli inferiori', (
    tester,
  ) async {
    final model = AuraArenaModel(), user = FakeUserModel(userChannel: channel);
    addTearDown(model.dispose);
    addTearDown(user.dispose);
    final api = fakeApiFor(user.accounts.single);
    model.sent(channel, '!Creatorneo');
    await tester.pumpWidget(
      app(model, user, AuraContextCards(channel: channel)),
    );
    expect(find.text('ForzaTorneo'), findsOneWidget);
    expect(find.text('Iniziatorneo'), findsNothing);
    expect(find.text('Partecipa al Torneo'), findsNothing);
    await tester.tap(find.text('Senza Forzare'));
    await tester.pumpAndSettle();
    expect(api.calls, isEmpty);
    expect(find.text('Partecipa al Torneo'), findsOneWidget);
    expect(find.text('ForzaTorneo'), findsNothing);
    expect(find.text('Iniziatorneo'), findsNothing);
    await tester.tap(find.text('Non partecipare'));
    await tester.pumpAndSettle();
    expect(api.calls, isEmpty);
    expect(find.text('Iniziatorneo'), findsOneWidget);
    expect(find.text('Partecipa al Torneo'), findsNothing);
    await tester.tap(find.text('Iniziatorneo'));
    await tester.pumpAndSettle();
    expect(api.calls.single.data['message'], '!Iniziatorneo');
    expect(find.text('Iniziatorneo'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Aura recipient commands prefill the composer and never send incomplete messages',
    (tester) async {
      final model = AuraArenaModel(),
          user = FakeUserModel(userChannel: channel);
      addTearDown(model.dispose);
      addTearDown(user.dispose);
      final api = fakeApiFor(user.accounts.single), composed = <String>[];
      await tester.pumpWidget(
        app(
          model,
          user,
          AuraCommandPanel(channel: channel, onCompose: composed.add),
        ),
      );
      await tester.tap(find.text('Solo utenti'));
      await tester.pumpAndSettle();
      for (final command in ['!Sfida', '!Puntiaura', '!Vincites']) {
        await tester.scrollUntilVisible(
          find.text(command),
          180,
          scrollable: find.byType(Scrollable).last,
        );
        await tester.tap(find.text(command));
        await tester.pumpAndSettle();
        expect(composed.last, '$command ');
        expect(find.byType(AlertDialog), findsNothing);
        expect(api.calls, isEmpty);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('Aura: percorso ForzaTorneo, Partecipa, Iniziatorneo in ordine', (
    tester,
  ) async {
    final model = AuraArenaModel(), user = FakeUserModel(userChannel: channel);
    addTearDown(model.dispose);
    addTearDown(user.dispose);
    final api = fakeApiFor(user.accounts.single);
    model.sent(channel, '!Creatorneo');
    await tester.pumpWidget(
      app(model, user, AuraContextCards(channel: channel)),
    );
    await tester.tap(find.text('ForzaTorneo'));
    await tester.pumpAndSettle();
    expect(find.text('Iniziatorneo'), findsNothing);
    await tester.tap(find.text('Partecipa al Torneo'));
    await tester.pumpAndSettle();
    expect(find.text('Iniziatorneo'), findsOneWidget);
    expect(find.text('ForzaTorneo'), findsNothing);
    await tester.tap(find.text('Iniziatorneo'));
    await tester.pumpAndSettle();
    expect(api.calls.map((c) => c.data['message']), [
      '!ForzaTorneo',
      '!Partecipatorneo',
      '!Iniziatorneo',
    ]);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets(
    'Aura: pannello compatto a360px con anteprima e testo ingrandito',
    (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final model = AuraArenaModel(),
          user = FakeUserModel(userChannel: channel);
      addTearDown(model.dispose);
      addTearDown(user.dispose);
      await tester.pumpWidget(
        app(
          model,
          user,
          MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              textScaler: TextScaler.linear(1.3),
            ),
            child: AuraCommandPanel(channel: channel),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
