import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rtchat/audio_channel.dart';
import 'package:rtchat/models/tts/embedded_engine.dart';
import 'package:rtchat/speaker_keep_alive.dart';
import 'fixtures/audio_mix_video.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'Real donated-video audio remains audible with bundled speech, mascot audio and keep-alive',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Verifica video + voci + mascotte')),
        ),
      );
      final external = await getExternalStorageDirectory();
      final deadline = DateTime.now().add(const Duration(seconds: 45));
      while (!await AudioChannel.hasPermission() &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
      expect(await AudioChannel.hasPermission(), true);
      const service = MethodChannel('com.rtirl.chat/tts_service');
      await service.invokeMethod('start', {
        'title': 'APPISHOWDRIVE QA',
        'text': 'Video + voce',
        'turnOff': 'Stop',
      });
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0),
          samples = <Map<String, dynamic>>[];
      final video = base64Decode(audioMixVideoBase64);
      var pageLoads = 0, pause = false;
      server.listen((request) async {
        if (request.uri.path == '/tick') {
          samples.add({
            'at': DateTime.now().millisecondsSinceEpoch,
            'time':
                double.tryParse(request.uri.queryParameters['time'] ?? '') ?? 0,
            'paused': request.uri.queryParameters['paused'] == 'true',
            'ready':
                int.tryParse(request.uri.queryParameters['ready'] ?? '') ?? 0,
          });
          request.response.statusCode = 204;
        } else if (request.uri.path == '/control') {
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'pause': pause}));
        } else if (request.uri.path == '/clip.mp4') {
          request.response.headers.contentType = ContentType('video', 'mp4');
          request.response.add(video);
        } else if (request.uri.path == '/') {
          pageLoads++;
          request.response.headers.contentType = ContentType.html;
          request.response.write(
            r'''<html><body><video id="video" autoplay loop playsinline src="/clip.mp4" width="128" height="72"></video><script>
const v=document.querySelector('video');v.volume=.1;v.play().catch(()=>{});
setInterval(()=>fetch('/tick?time='+v.currentTime+'&paused='+v.paused+'&ready='+v.readyState).catch(()=>{}),100);
let command=false;setInterval(()=>fetch('/control').then(r=>r.json()).then(c=>{if(c.pause!==command){command=c.pause;if(command)v.pause();else v.play().catch(()=>{});}}).catch(()=>{}),100);
</script></body></html>''',
          );
        } else {
          request.response.statusCode = 404;
        }
        await request.response.close();
      });
      final engine = EmbeddedItalianEngine(), errors = <Object>[];
      final keepAlive = SpeakerKeepAlive(
            onError: (error, _) => errors.add(error),
          ),
          welcome = AudioPlayer();
      await welcome.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
            usageType: AndroidUsageType.media,
            contentType: AndroidContentType.speech,
          ),
        ),
      );
      addTearDown(() async {
        await keepAlive.dispose();
        await engine.dispose();
        await welcome.dispose();
        await AudioChannel.set([]);
        await service.invokeMethod('stop');
        await server.close(force: true);
      });
      final url = 'http://127.0.0.1:${server.port}/';
      expect(await AudioChannel.set([url]), true);
      final ready = DateTime.now().add(const Duration(seconds: 30));
      while (samples.where((s) => s['ready'] >= 2 && !s['paused']).length <
              10 &&
          DateTime.now().isBefore(ready)) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(samples.where((s) => s['ready'] >= 2), isNotEmpty);
      await Future<void>.delayed(const Duration(seconds: 1));
      final speechStart = DateTime.now().millisecondsSinceEpoch;
      final voices = await engine.voices(language: 'it');
      final speech = <Map<String, dynamic>>[];
      for (final id in ['F1', 'M1', 'F3', 'M5']) {
        await AudioChannel.set([url]);
        await keepAlive.ping();
        final at = DateTime.now().millisecondsSinceEpoch;
        if (id == 'M1') await welcome.play(AssetSource('welcome/voice.mp3'));
        await engine.speak(
          'Ciao chat, buon viaggio a tutti!',
          voice: voices.firstWhere((v) => v.id == id),
        );
        speech.add({
          'voice': id,
          'startAt': at,
          'endAt': DateTime.now().millisecondsSinceEpoch,
        });
      }
      final speechEnd = DateTime.now().millisecondsSinceEpoch;
      final during =
          samples
              .where(
                (s) =>
                    s['at'] >= speechStart &&
                    s['at'] <= speechEnd &&
                    s['ready'] >= 2,
              )
              .toList();
      expect(during.length, greaterThan(20));
      expect(during.where((s) => s['paused']), isEmpty);
      expect(during.map((s) => s['time']).toSet().length, greaterThan(20));
      expect(pageLoads, 1);
      expect(errors, isEmpty);
      final silenceStart = DateTime.now().millisecondsSinceEpoch;
      pause = true;
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      final silenceEnd = DateTime.now().millisecondsSinceEpoch;
      pause = false;
      await Future<void>.delayed(const Duration(milliseconds: 1600));
      final report = {
        'model': 'Kokoro Italian profiles v1',
        'speechStartAt': speechStart,
        'speechEndAt': speechEnd,
        'controlSilenceStartAt': silenceStart,
        'controlSilenceEndAt': silenceEnd,
        'audioPilotHz': 9971,
        'voices': speech,
        'mascotDuringSpeech': true,
        'pageLoads': pageLoads,
        'videoSamplesDuringSpeech': during.length,
        'privateSoundAlertsUrlTested': false,
      };
      await File(
        '${external!.path}/embedded-audio-report.json',
      ).writeAsString(jsonEncode(report));
      debugPrint('APPISHOWDRIVE_EMBEDDED_AUDIO_REPORT ${jsonEncode(report)}');
      await Future<void>.delayed(const Duration(seconds: 15));
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
