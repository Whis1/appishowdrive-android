import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import 'package:integration_test/integration_test.dart';
import 'package:rtchat/models/messages/kick/message.dart';
import 'package:rtchat/models/messages/kick/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/api.dart';
import 'package:rtchat/components/chat_history/message.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/components/drive_brand.dart';
import 'package:rtchat/components/header_bar.dart';
import 'package:rtchat/components/message_input.dart';
import 'package:rtchat/components/emote_picker.dart';
import 'package:rtchat/components/style_model_theme.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/adapters/channels.dart';
import 'package:rtchat/models/aura_arena.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/commands.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/emote.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/views.dart';
import 'package:rtchat/screens/settings/tts.dart';
import 'package:rtchat/screens/settings/interface_themes.dart';
import 'package:rtchat/themes.dart';
import '../test/fakes/fake_api.dart';
import '../test/fakes/fake_chat.dart';
import '../test/fakes/fake_tts_engine.dart';
import '../test/fakes/fake_user_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Production community widgets: visual review and interactive flow', (
    tester,
  ) async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('com.rtirl.chat/share'),
          (_) async => '',
        );
    final channel = Channel(Providers.twitch, '42', 'Ishowdrive'),
        user = FakeUserModel(
          userChannel: Channel(Providers.twitch, '42', 'Ishowdrive'),
        ),
        aura = AuraArenaModel();
    final api = fakeApiFor(user.accounts.single);
    addTearDown(Api.debugReset);
    addTearDown(user.dispose);
    addTearDown(aura.dispose);
    final tts = TtsModel.fromJson({}, engine: FakeTtsEngine());
    addTearDown(tts.dispose);
    final key = GlobalKey();
    final navigator = GlobalKey<NavigatorState>();
    Future<void> capture(String name) async {
      await tester.pumpAndSettle();
      final exception = tester.takeException();
      final image = await tester.runAsync(
        () => (key.currentContext!.findRenderObject()! as RenderRepaintBoundary)
            .toImage(pixelRatio: 2),
      );
      final data = await tester.runAsync(
        () => image!.toByteData(format: ui.ImageByteFormat.png),
      );
      await tester.runAsync(() async {
        final out = Directory(
          '${(await getExternalStorageDirectory())!.path}/qa-screens',
        );
        await out.create(recursive: true);
        await File(
          '${out.path}/$name.png',
        ).writeAsBytes(data!.buffer.asUint8List());
      });
      image!.dispose();
      debugPrint(name);
      expect(exception, isNull);
    }

    final texts = [
      ('Alice', 'Buon viaggio Pit! Dove siamo diretti oggi? 🚛'),
      ('Mauro', 'L’Impero Lanzichenecco non si ferma mai!'),
      ('Luca', '!Ruotas'),
      ('Sofia', 'Saluti anche dalla chat di Kick!'),
    ];
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider<UserModel>.value(value: user),
            ChangeNotifierProvider<AuraArenaModel>.value(value: aura),
            ChangeNotifierProvider<TtsModel>.value(value: tts),
            ChangeNotifierProvider(create: (_) => StyleModel.fromJson({})),
            ChangeNotifierProvider(create: (_) => LayoutModel.fromJson({})),
            ChangeNotifierProvider(create: (_) => ViewsModel.fromJson({})),
            ChangeNotifierProvider(create: (_) => CommandsModel.fromJson({})),
          ],
          child: MaterialApp(
            navigatorKey: navigator,
            theme: Themes.darkTheme,
            locale: const Locale('it'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              drawer: const Drawer(
                child: SafeArea(
                  child: Column(
                    children: [
                      DriveBrand(),
                      ListTile(title: Text('Dati di prova · verifica locale')),
                    ],
                  ),
                ),
              ),
              appBar: HeaderBarWidget(
                channel: channel,
                onChannelSelect: (_) {},
                metadataFor:
                    (_) => Stream.value(
                      StreamChannelMetadata(
                        viewerCount: 352,
                        onlineAt: DateTime.now().subtract(
                          const Duration(hours: 3),
                        ),
                      ),
                    ),
              ),
              body: Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8),
                    child: Text(
                      'DATI DI PROVA',
                      style: TextStyle(fontSize: 10, letterSpacing: 2),
                    ),
                  ),
                  Expanded(
                    child: StyleModelTheme(
                      child: ListView(
                        children: [
                          for (final (i, text) in texts.indexed)
                            ChatHistoryMessage(
                              channel:
                                  i.isOdd
                                      ? Channel('kick', '43', 'IshowdriveKick')
                                      : channel,
                              message:
                                  i.isOdd
                                      ? KickMessageModel(
                                        messageId: 'k$i',
                                        timestamp: DateTime.now(),
                                        author: KickUserModel(
                                          userId: 'u$i',
                                          login: text.$1.toLowerCase(),
                                          displayName: text.$1,
                                        ),
                                        message: text.$2,
                                        channelId: 'kick:43',
                                      )
                                      : TwitchMessageModel(
                                        messageId: 'm$i',
                                        author: TwitchUserModel(
                                          userId: 'u$i',
                                          login: text.$1.toLowerCase(),
                                          displayName: text.$1,
                                        ),
                                        tags: const {},
                                        annotations:
                                            const TwitchMessageAnnotationsModel(
                                              isAction: false,
                                              isFirstTimeChatter: false,
                                              announcement: null,
                                            ),
                                        thirdPartyEmotes: const [],
                                        timestamp: DateTime.now(),
                                        message: text.$2,
                                        deleted: false,
                                        channelId: 'twitch:42',
                                      ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  MessageInputWidget(
                    channel: channel,
                    loadEmotes:
                        (_) async => [
                          Emote(
                            provider: 'twitch',
                            category: null,
                            id: '425618',
                            code: 'LUL',
                            imageUrl:
                                'https://static-cdn.jtvnw.net/emoticons/v2/425618/default/light/2.0',
                          ),
                        ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('TWITCH'), findsNothing);
    expect(find.text('KICK'), findsNothing);
    final platformIcon = find.byType(ProviderIcon).first;
    final aliceText = find.byWidgetPredicate(
      (w) =>
          w is RichText && w.text.toPlainText().contains('Buon viaggio Pit!'),
    );
    expect(
      tester.getTopLeft(platformIcon).dx,
      greaterThan(tester.getTopLeft(aliceText).dx),
    );
    await capture('chat');
    await tester.tap(find.byTooltip('Emote'));
    await tester.pumpAndSettle();
    expect(find.byType(EmotePickerWidget), findsOneWidget);
    await capture('emotes-preservees');
    await tester.tap(find.byIcon(Icons.keyboard_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Aura Arena'));
    await capture('comandi-aura');
    await tester.tap(find.text('!Apriudienze'));
    await capture('udienze-quattro-decisioni');
    await tester.tap(find.text('!Chiudiudienze'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('!Creatorneo'));
    await capture('torneo-forza');
    await tester.tap(find.text('Senza Forzare'));
    await capture('torneo-partecipa');
    await tester.tap(find.text('Non partecipare'));
    await capture('torneo-avvio');
    aura.observe(
      channel,
      FakeChatMessage(
        messageId: 'invite',
        timestamp: DateTime.now(),
        author: const FakeChatUser(
          provider: 'twitch',
          userId: 'bot',
          login: 'ufonibiru',
        ),
        message: '@Ishowdrive, Alice ti sfida! Scrivi !accetta entro 1 minuto.',
      ),
      recipient: 'Ishowdrive',
    );
    await capture('sfida-accetta-ignora');
    await tester.tap(find.text('Ignora'));
    await tester.pumpAndSettle();
    navigator.currentState!.push(
      MaterialPageRoute(builder: (_) => const TextToSpeechScreen()),
    );
    await capture('tts-android-sistema');
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    navigator.currentState!.push(
      MaterialPageRoute(builder: (_) => const InterfaceThemesScreen()),
    );
    await capture('colori-interfaccia');
    await tester.tap(find.text('Viola'));
    await tester.pumpAndSettle();
    expect(
      tester
          .element(find.byType(InterfaceThemesScreen))
          .read<LayoutModel>()
          .interfaceTheme,
      InterfaceTheme.viola,
    );
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(api.calls.map((c) => c.data['message']), [
      '!Apriudienze',
      '!Chiudiudienze',
      '!Creatorneo',
    ]);
    await Future<void>.delayed(const Duration(seconds: 15));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
