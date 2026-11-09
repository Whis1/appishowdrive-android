import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/welcome_mascot.dart';
import 'package:rtchat/components/chat_history/twitch/nickname_paint.dart';
import 'package:rtchat/models/chat_identity.dart';
import 'package:rtchat/models/chat_paints.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/style.dart';
import 'package:rtchat/models/messages/twitch/badge.dart';
import 'package:rtchat/models/messages/twitch/user.dart';
import 'package:rtchat/models/adapters/chat_state.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/embedded_engine.dart';
import 'package:rtchat/screens/settings/badge_settings.dart';
import 'package:rtchat/themes.dart';
import 'fakes/fake_tts_engine.dart';

void main() {
  test(
    'One Twitch name only, including international names and old preferences',
    () {
      final model = StyleModel.fromJson({'isLoginShown': true});
      const user = TwitchUserModel(
        userId: '42',
        login: 'daishxvii',
        displayName: 'どこでも兼',
      );
      expect(model.getDisplayName(user), 'どこでも兼');
      model.isLoginShown = true;
      expect(model.getDisplayName(user), 'daishxvii');
      final restored = StyleModel.fromJson(model.toJson());
      expect(restored.getDisplayName(user), 'daishxvii');
      model.dispose();
      restored.dispose();
    },
  );
  test(
    'Badge defaults survive persistence; explicit deselection survives migration',
    () {
      final fresh = TwitchBadgeModel.fromJson({});
      final legacy = TwitchBadgeModel.fromJson({'enabled': []});
      expect(fresh.isEnabled('moderator'), isTrue);
      expect(legacy.isEnabled('subscriber'), isTrue);
      fresh.localBadgeSets = [
        TwitchBadgeInfo(setId: 'subscriber', versions: []),
      ];
      fresh.globalBadgeSets = [
        TwitchBadgeInfo(setId: 'subscriber', versions: []),
        TwitchBadgeInfo(setId: 'moderator', versions: []),
      ];
      fresh.setEnabled('moderator', false);
      expect(fresh.isEnabled('subscriber'), isTrue);
      expect(fresh.isEnabled('moderator'), isFalse);
      final restored = TwitchBadgeModel.fromJson(fresh.toJson());
      expect(restored.isEnabled('moderator'), isFalse);
      fresh.setAllEnabled(false);
      expect(
        TwitchBadgeModel.fromJson(fresh.toJson()).isEnabled('subscriber'),
        isFalse,
      );
      fresh.dispose();
      legacy.dispose();
      restored.dispose();
    },
  );
  test(
    'Public badge providers use Twitch IDs and reject unsafe image URLs',
    () {
      final ffz = ChatIdentityModel.parse('ffz', {
        'badges': [
          {
            'id': 7,
            'title': 'FFZ',
            'urls': {'4': '//cdn.frankerfacez.com/badge.png'},
          },
        ],
        'users': {
          '7': [42],
        },
      });
      expect(ffz['42']!.single.provider, 'ffz');
      expect(ffz['42']!.single.url, startsWith('https://'));
      expect(
        ChatIdentityModel.parse('bttv', [
          {
            'providerId': '42',
            'badge': {'svg': 'http://bad.test/a.svg'},
          },
        ]),
        isEmpty,
      );
      final chatterino = ChatIdentityModel.parse('chatterino', {
        'badges': [
          {
            'users': ['42'],
            'image3': 'https://chatterino.com/badge.png',
            'tooltip': 'Supporter',
          },
        ],
      });
      expect(chatterino['42']!.single.title, 'Supporter');
    },
  );
  test(
    'Pronouns are self selected, bound to matching Twitch identity, deduplicated and cached',
    () async {
      final calls = <String>[];
      final model = ChatIdentityModel(
        fetch: (uri) async {
          calls.add(uri.path);
          if (uri.path.endsWith('/pronouns')) {
            return {
              'hehim': {'subject': 'He', 'object': 'Him', 'singular': false},
            };
          }
          return {
            'channel_id': uri.path.endsWith('/alice') ? '42' : '999',
            'pronoun_id': 'hehim',
          };
        },
      );
      addTearDown(model.dispose);
      for (var i = 0; i < 20; i++) {
        model.ensurePronouns('42', 'alice');
      }
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(model.pronounsFor('42'), 'He/Him');
      model.ensurePronouns('42', 'alice');
      expect(calls.where((s) => s.endsWith('/alice')).length, 1);
      model.ensurePronouns('43', 'bob');
      await Future<void>.delayed(Duration.zero);
      expect(model.pronounsFor('43'), isNull);
    },
  );
  test(
    '7TV caches public active paint; absent/failed lookups do not request repeatedly',
    () async {
      var calls = 0;
      final model = ChatPaintModel(
        fetch: (id) async {
          calls++;
          return {
            'data': {
              'users': {
                'userByConnection': {
                  'style': {
                    'activePaint': {
                      'name': 'Gold',
                      'data': {'layers': [], 'shadows': []},
                    },
                  },
                },
              },
            },
          };
        },
      );
      addTearDown(model.dispose);
      for (var i = 0; i < 50; i++) {
        model.ensure('42');
      }
      await Future<void>.delayed(Duration.zero);
      expect(model.paintFor('42')!['name'], 'Gold');
      model.ensure('42');
      model.ensure('invalid');
      expect(calls, 1);
      expect(paintColor({'hex': '#39D21EFF'}), const Color(0xff39d21e));
      expect(paintColor({'hex': '#00555780'}).a, closeTo(128 / 255, .001));
    },
  );
  testWidgets(
    'All/individual identity controls persist; Twitch advanced selection is included',
    (tester) async {
      final style = StyleModel.fromJson({}),
          badges = TwitchBadgeModel.fromJson({});
      addTearDown(style.dispose);
      addTearDown(badges.dispose);
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: style),
            ChangeNotifierProvider.value(value: badges),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(child: ChatIdentitySettings()),
            ),
          ),
        ),
      );
      expect(
        tester
            .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
            .every((w) => w.value == true),
        isTrue,
      );
      await tester.tap(find.text('Disattiva tutto'));
      await tester.pump();
      expect(badges.isEnabled('moderator'), isFalse);
      expect(
        identitySources.keys.every((s) => !style.badgesVisible(s)),
        isTrue,
      );
      await tester.tap(find.text('Badge Twitch'));
      await tester.pump();
      expect(style.badgesVisible('twitch'), isTrue);
      expect(badges.isEnabled('moderator'), isTrue);
      await tester.tap(find.text('Attiva tutto'));
      await tester.pump();
      expect(badges.isEnabled('moderator'), isTrue);
      await tester.ensureVisible(find.text('Badge FrankerFaceZ'));
      await tester.tap(find.text('Badge FrankerFaceZ'));
      await tester.pump();
      final restored = StyleModel.fromJson(style.toJson());
      expect(restored.badgesVisible('ffz'), isFalse);
      expect(restored.badgesVisible('chatterino'), isTrue);
      restored.dispose();
    },
  );
  testWidgets(
    'Only black changes: all other nickname colours keep the original boost exactly',
    (tester) async {
      final model = StyleModel.fromJson({});
      addTearDown(model.dispose);
      for (final theme in InterfaceTheme.values) {
        await tester.pumpWidget(
          MaterialApp(
            theme: Themes.darkFor(theme),
            home: Builder(
              builder: (context) {
                final black = model.applyLightnessBoost(context, Colors.black);
                final background = Theme.of(context).colorScheme.surface;
                expect(
                  (black.computeLuminance() + .05) /
                      (background.computeLuminance() + .05),
                  greaterThanOrEqualTo(4.49),
                );
                for (final colour in [
                  Colors.red,
                  Colors.green,
                  Colors.blue,
                  const Color(0xff9146ff),
                  Colors.white,
                ]) {
                  expect(
                    model.applyLightnessBoost(context, colour),
                    lighten(colour, model.lightnessBoost),
                  );
                }
                return const SizedBox();
              },
            ),
          ),
        );
      }
    },
  );
  test(
    'Welcome is claimed only after login, once per process, with a persistent opt-out',
    () {
      final session = WelcomeSession();
      expect(session.claim(signedIn: false, enabled: true), isFalse);
      expect(session.claim(signedIn: true, enabled: true), isTrue);
      expect(session.claim(signedIn: true, enabled: true), isFalse);
      final disabled = WelcomeSession();
      expect(disabled.claim(signedIn: true, enabled: false), isFalse);
      expect(disabled.claim(signedIn: true, enabled: true), isFalse);
      expect(WelcomeSession().claim(signedIn: true, enabled: true), isTrue);
      final layout = LayoutModel.fromJson({})..welcomeMascot = false;
      expect(LayoutModel.fromJson(layout.toJson()).welcomeMascot, isFalse);
      layout.dispose();
    },
  );
  test(
    'Supertonic settings migrate to Android without changing speed, pitch or mutes',
    () {
      final migrated = TtsModel.migrateCommunitySettings({
        'platformVoices': {'twitch': 'F1'},
        'voicePack': 'supertonic-3',
        'speed': .65,
        'pitch': .8,
        'mutedUsers': [],
      });
      expect(migrated['platformVoices'], {
        'twitch': 'system',
        'kick': 'system',
      });
      expect(migrated['voicePack'], isNull);
      expect(migrated['speed'], .65);
      expect(migrated['pitch'], .8);
      expect(
        TtsModel.migrateCommunitySettings({
          ...migrated,
          'platformVoices': {'twitch': 'M2'},
        })['platformVoices'],
        {'twitch': 'M2', 'kick': 'system'},
      );
    },
  );
  test(
    'Android previews never enter the neural engine; failed neural preview recovers to Android',
    () async {
      final system = FakeTtsEngine(),
          neural = FakeTtsEngine(
            availableVoices: const [
              TtsVoice(id: 'F1', name: 'Sara', locale: 'it'),
            ],
          );
      final model = TtsModel.fromJson(
        TtsModel.migrateCommunitySettings({}),
        engine: system,
        reportError: (_, _) {},
      )..neuralEngine = neural;
      addTearDown(model.dispose);
      await model.previewSample(language: 'it');
      expect(system.spoken.length, 1);
      expect(neural.spoken, isEmpty);
      await model.previewVoice('it', 'system', 'Android');
      expect(system.spoken.last, 'Android');
      await model.previewVoice('it', 'F1', 'Sara');
      expect(neural.spoken.last, 'Sara');
      neural.failNext = StateError('worker stopped');
      await model.previewVoice('it', 'F1', 'Ripiego');
      expect(system.spoken.last, 'Ripiego');
    },
  );
  test('Bundled catalog offers ten distinct selectable profiles', () async {
    final engine = EmbeddedItalianEngine();
    final voices = await engine.voices(language: 'it');
    expect(voices.map((v) => v.id).toSet().length, 10);
    expect(voices.where((v) => v.id.startsWith('F')).length, 5);
    expect(voices.where((v) => v.id.startsWith('M')).length, 5);
    expect(await engine.voices(language: 'fr'), isEmpty);
  });
}
