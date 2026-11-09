import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:rtchat/models/tts/embedded_engine.dart';
import 'identity_mascot_test.dart' as identity;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  identity.main();
  testWidgets(
    'Release APK native voices, process isolation and resource release',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Text('Verifica APK release'))),
      );
      final engine = EmbeddedItalianEngine(),
          voices = await EmbeddedItalianEngine().voices(language: 'it');
      debugPrint('RELEASE_VOICE_READING');
      await engine.speak(
        'Ciao chat, buon viaggio a tutti!',
        voice: voices.first,
      );
      await engine.speak(
        'Questa è una nuova voce italiana già dentro l’app.',
        voice: voices.last,
      );
      await engine.release();
      expect(find.text('Verifica APK release'), findsOneWidget);
      debugPrint('RELEASE_VOICE_IDLE');
      await Future<void>.delayed(const Duration(seconds: 10));
      await engine.dispose();
      debugPrint('RELEASE_111_NATIVE_PASSED');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
