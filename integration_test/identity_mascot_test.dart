import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/welcome_mascot.dart';
import 'package:rtchat/components/chat_history/twitch/message.dart';
import 'package:rtchat/models/chat_identity.dart';
import 'package:rtchat/models/chat_paints.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/views.dart';
import 'package:rtchat/models/channels.dart';
import 'package:rtchat/models/adapters/chat_state.dart';
import 'package:rtchat/models/messages/twitch/badge.dart';
import 'package:rtchat/models/messages/twitch/message.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/screens/settings/badge_settings.dart';
import 'package:rtchat/themes.dart';
import '../test/fakes/fake_user_model.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('Native badge/paint rendering and welcome mascot touch/lifecycle', (
    tester,
  ) async {
    final channel = Channel('twitch', '42', 'Ishowdrive');
    final user = FakeUserModel(userChannel: channel),
        views = ViewsModel.fromJson({})..openChannel(channel);
    final style = StyleModel.fromJson({}), layout = LayoutModel.fromJson({});
    final badges = TwitchBadgeModel.fromJson({});
    const mod =
        'https://static-cdn.jtvnw.net/badges/v1/3267646d-33f0-4b17-b3df-f923a41db1d0/3';
    badges.globalBadgeSets = [
      TwitchBadgeInfo(
        setId: 'moderator',
        versions: [
          BadgeVersion(
            id: '1',
            imageUrl1x: mod,
            imageUrl2x: mod,
            imageUrl4x: mod,
            description: 'Moderatore',
            title: 'Moderatore',
            clickAction: null,
            clickUrl: null,
          ),
        ],
      ),
    ];
    final identities = ChatIdentityModel(
      fetch: (uri) async {
        if (uri.host == 'api.pronouns.alejo.io') {
          if (uri.path.endsWith('/pronouns')) {
            return {
              'hehim': {'subject': 'He', 'object': 'Him', 'singular': false},
            };
          }
          return {'channel_id': '42', 'pronoun_id': 'hehim'};
        }
        if (uri.host == 'api.frankerfacez.com') {
          return {
            'badges': [
              {
                'id': 1,
                'title': 'FrankerFaceZ',
                'urls': {'4': 'https://cdn.frankerfacez.com/badge/2/4'},
              },
            ],
            'users': {
              '1': [42],
            },
          };
        }
        return null;
      },
    );
    final paints = ChatPaintModel();
    paints.ensure('71092938');
    await identities.ensureBadges(['ffz']);
    identities.ensurePronouns('42', 'alice');
    final navigator = GlobalKey<NavigatorState>(), boundary = GlobalKey();
    var taps = 0;
    TwitchMessageModel message(
      String id,
      String login,
      String text,
      String colour,
    ) => TwitchMessageModel(
      messageId: id,
      author: TwitchUserModel(userId: id, login: login, displayName: login),
      message: text,
      tags: {
        'color': colour,
        'badges': {'moderator': '1'},
      },
      annotations: const TwitchMessageAnnotationsModel(
        isAction: false,
        isFirstTimeChatter: false,
        announcement: null,
      ),
      thirdPartyEmotes: [],
      timestamp: DateTime.now(),
      deleted: false,
      channelId: '42',
    );
    Future<void> capture(String name) async {
      await tester.pump(const Duration(milliseconds: 30));
      final screenshot = await (boundary.currentContext!.findRenderObject()
              as RenderRepaintBoundary)
          .toImage(pixelRatio: 2);
      final bytes = await screenshot.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory(
        '${(await getExternalStorageDirectory())!.path}/identity-qa',
      )..createSync(recursive: true);
      await File(
        '${dir.path}/$name.png',
      ).writeAsBytes(bytes!.buffer.asUint8List());
      screenshot.dispose();
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<UserModel>.value(value: user),
          ChangeNotifierProvider.value(value: views),
          ChangeNotifierProvider.value(value: style),
          ChangeNotifierProvider.value(value: layout),
          ChangeNotifierProvider.value(value: badges),
          ChangeNotifierProvider.value(value: identities),
          ChangeNotifierProvider.value(value: paints),
        ],
        child: RepaintBoundary(
          key: boundary,
          child: MaterialApp(
            navigatorKey: navigator,
            theme: Themes.darkFor(InterfaceTheme.rosso),
            builder: (context, child) => WelcomeMascotHost(child: child!),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('APPISHOWDRIVE · DATI DI PROVA'),
              ),
              body: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  TwitchMessageWidget(
                    message(
                      '42',
                      'Alice',
                      'Il nickname nero ora si legge.',
                      '#000000',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TwitchMessageWidget(
                    message(
                      '71092938',
                      'Nome7TV',
                      'Il tema è quello scelto su 7TV.',
                      '#9146FF',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TwitchMessageWidget(
                    message(
                      '43',
                      'Mauro',
                      'Gli altri colori restano come prima.',
                      '#00FF7F',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Builder(
                    builder:
                        (context) => ElevatedButton(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BadgeSettingsScreen(),
                                ),
                              ),
                          child: const Text('Impostazioni'),
                        ),
                  ),
                ],
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => taps++,
                child: const Icon(Icons.touch_app),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1600)),
    );
    await tester.pump();
    await capture('welcome-speaking');
    await tester.tap(find.byType(FloatingActionButton));
    expect(taps, 1, reason: 'The visible mascot must not consume touches.');
    await tester.tap(find.text('Impostazioni'));
    await tester.pump(const Duration(milliseconds: 350));
    await capture('welcome-over-settings');
    navigator.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 350));
    final smileDeadline = DateTime.now().add(const Duration(seconds: 6));
    bool smiling() => tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .any(
          (w) =>
              w.painter is MascotPainter &&
              (w.painter as MascotPainter).mouth == 'smile',
        );
    while (!smiling() && DateTime.now().isBefore(smileDeadline)) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();
    }
    expect(
      smiling(),
      isTrue,
      reason:
          'After the real audio completes, closed-lip smile must remain during hold/fade.',
    );
    await capture('welcome-closed-lip-smile');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 3)),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(AnimatedOpacity), findsNothing);
    await capture('badges-and-7tv');
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 200));
    expect(
      find.byType(AnimatedOpacity),
      findsNothing,
      reason: 'Browser/page resumes must not replay the greeting.',
    );
    await tester.tap(find.text('Impostazioni'));
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('Disattiva tutto'));
    await tester.pump();
    expect(style.badgesVisible('7tv'), false);
    expect(badges.isEnabled('moderator'), false);
    navigator.currentState!.pop();
    await tester.pump(const Duration(milliseconds: 350));
    await capture('all-extensions-disabled');
    debugPrint('IDENTITY_MASCOT_NATIVE_OK');
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(seconds: 15)),
    );
    await tester.pumpWidget(const SizedBox());
    for (final model in [
      user,
      views,
      style,
      layout,
      badges,
      identities,
      paints,
    ]) {
      model.dispose();
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}
