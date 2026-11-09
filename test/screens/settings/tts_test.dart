import 'package:flutter/material.dart';
import 'package:flutter_localized_locales/flutter_localized_locales.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/l10n/app_localizations.dart';
import 'package:rtchat/models/tts.dart';
import 'package:rtchat/screens/settings/tts.dart';

import '../../fakes/fake_tts_engine.dart';

void main() {
  testWidgets('TTS settings use only Android system speech and preserve controls', (
    tester,
  ) async {
    final engine = FakeTtsEngine();
    final model = TtsModel.fromJson(
      TtsModel.migrateCommunitySettings({
        'speechEngine': 'kokoro-v1',
        'voicePack': 'supertonic-3',
        'neuralVoices': {'it': 'F1'},
        'platformVoices': {'twitch': 'M2'},
        'speed': .65,
        'pitch': .8,
      }),
      engine: engine,
      reportError: (error, _) => throw error,
    );
    addTearDown(model.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: model,
        child: const MaterialApp(
          localizationsDelegates: [
            ...AppLocalizations.localizationsDelegates,
            LocaleNamesLocalizationsDelegate(),
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: TextToSpeechScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('System voice'), findsOneWidget);
    expect(find.text('Voice packs'), findsNothing);
    expect(find.text('Voci italiane IA'), findsNothing);
    expect(find.text('Voce Android'), findsNothing);
    expect(model.toJson()['speechEngine'], 'system');
    expect(model.toJson().containsKey('voicePack'), isFalse);
    expect(model.toJson().containsKey('neuralVoices'), isFalse);
    expect(model.toJson().containsKey('platformVoices'), isFalse);

    await tester.tap(find.text('Play sample message'));
    await tester.pumpAndSettle();
    expect(engine.spoken, hasLength(1));
  });
}
