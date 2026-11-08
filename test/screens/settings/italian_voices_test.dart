import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/components/provider_icon.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/models/tts/voice_packs.dart';
import 'package:rtchat/screens/settings/tts/italian_voices.dart';
import '../../fakes/fake_tts_engine.dart';
import '../../fakes/fake_voice_pack_repository.dart';

void main() {
  Future<TtsModel> open(WidgetTester tester, {required bool installed}) async {
    final repo = FakeVoicePackRepository();
    if (installed) {
      repo.add(
        installedPackOf(
          bundledVoicePacks.firstWhere((p) => p.id == 'supertonic-3'),
        ),
      );
    }
    final packs = VoicePacksModel(repo, isSupported: true);
    final tts = TtsModel.fromJson({}, engine: FakeTtsEngine())
      ..neuralEngine = FakeTtsEngine(availableVoices: packVoices(['it']));
    addTearDown(packs.dispose);
    addTearDown(tts.dispose);
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: tts),
          ChangeNotifierProvider.value(value: packs),
        ],
        child: const MaterialApp(home: ItalianVoicesScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return tts;
  }

  testWidgets(
    'Italian voices cannot select an unavailable model; Android remains usable',
    (tester) async {
      await open(tester, installed: false);
      await tester.scrollUntilVisible(find.text('Voce femminile 1'), 300);
      final row = find.ancestor(
        of: find.text('Voce femminile 1'),
        matching: find.byType(Card),
      );
      for (final chip in tester.widgetList<FilterChip>(
        find.descendant(of: row, matching: find.byType(FilterChip)),
      )) {
        expect(chip.onSelected, isNull);
      }
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'Italian voice row independently selects Twitch and Kick with platform icons',
    (tester) async {
      final tts = await open(tester, installed: true);
      await tester.scrollUntilVisible(find.text('Voce femminile 1'), 300);
      final row = find.ancestor(
        of: find.text('Voce femminile 1'),
        matching: find.byType(Card),
      );
      expect(
        find.descendant(of: row, matching: find.byType(ProviderIcon)),
        findsNWidgets(2),
      );
      for (final platform in ['Twitch', 'Kick']) {
        final chip = find.descendant(
          of: row,
          matching: find.widgetWithText(FilterChip, 'Usa per $platform'),
        );
        await tester.ensureVisible(chip);
        await tester.tap(chip);
        await tester.pump();
      }
      expect(tts.platformVoice('twitch'), 'F1');
      expect(tts.platformVoice('kick'), 'F1');
      await tester.pumpWidget(const SizedBox());
    },
  );
}
