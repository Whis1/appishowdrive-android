import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rtchat/models/tts/embedded_engine.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Bundled speech: real offline synthesis in a separate Android process',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: Text('Prova voci integrate'))),
        ),
      );
      final engine = EmbeddedItalianEngine();
      final samples = <Map<String, dynamic>>[];
      final voices = await engine.voices(language: 'it');
      expect(voices.length, 10);
      for (final voice in voices) {
        final started = DateTime.now();
        await engine.speak(
          'Ciao, benvenuti su Ishowdrive. Come state? Buon viaggio a tutti!',
          voice: voice,
        );
        final seconds =
            DateTime.now().difference(started).inMilliseconds / 1000;
        samples.add({
          'startAt': started.millisecondsSinceEpoch,
          'endAt': DateTime.now().millisecondsSinceEpoch,
          'voice': voice.id,
          'name': voice.name,
          'elapsed': seconds,
        });
        debugPrint('EMBEDDED_VOICE ${jsonEncode(samples.last)}');
      }
      await engine.release();
      await engine.speak(
        'La voce torna a funzionare dopo il rilascio.',
        voice: voices.first,
      );
      final directory = await getExternalStorageDirectory();
      await File(
        '${directory!.path}/embedded-speech-report.json',
      ).writeAsString(jsonEncode({'voices': samples, 'reload': true}));
      debugPrint('EMBEDDED_SPEECH_OK ${jsonEncode(samples)}');
      await engine.dispose();
      await Future<void>.delayed(const Duration(seconds: 15));
    },
    timeout: const Timeout(Duration(minutes: 15)),
  );
  testWidgets(
    'Stopping the native worker leaves the app alive and a new worker can read again',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Interfaccia ancora attiva')),
        ),
      );
      final engine = EmbeddedItalianEngine();
      final reading = engine.speak(
        'Questa frase serve per verificare il recupero del motore vocale senza chiudere la chat. ' *
            8,
      );
      debugPrint('EMBEDDED_KILL_READY');
      await expectLater(reading, throwsA(isA<NeuralTtsLoadException>()));
      await tester.pump();
      expect(find.text('Interfaccia ancora attiva'), findsOneWidget);
      await engine.speak(
        'La chat è rimasta aperta e la voce funziona di nuovo.',
      );
      await engine.dispose();
      debugPrint('EMBEDDED_WORKER_RECOVERED');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
