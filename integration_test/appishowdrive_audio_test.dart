import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:on_device_tts/on_device_tts.dart';
import 'package:rtchat/audio_channel.dart';
import 'package:rtchat/speaker_keep_alive.dart';
import 'fixtures/audio_mix_video.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('video source stays playing throughout real native system speech', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('APPISHOWDRIVE · Video + TTS test')),
        ),
      ),
    );
    final deadline = DateTime.now().add(const Duration(seconds: 45));
    while (!await AudioChannel.hasPermission() &&
        DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }
    expect(
      await AudioChannel.hasPermission(),
      true,
      reason: 'Grant overlay permission on the QA emulator first.',
    );
    const service = MethodChannel('com.rtirl.chat/tts_service');
    await service.invokeMethod('start', {
      'title': 'APPISHOWDRIVE QA',
      'text': 'Video + TTS',
      'turnOff': 'Stop',
    });
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final video = base64Decode(audioMixVideoBase64),
        samples = <Map<String, dynamic>>[];
    var alertPageLoads = 0, videoFileRequests = 0;
    var pauseControl = false;
    server.listen((req) async {
      if (req.uri.path == '/tick') {
        samples.add({
          'at': DateTime.now().millisecondsSinceEpoch,
          'time': double.tryParse(req.uri.queryParameters['time'] ?? '') ?? 0,
          'paused': req.uri.queryParameters['paused'] == 'true',
          'ready': int.tryParse(req.uri.queryParameters['ready'] ?? '') ?? 0,
        });
        req.response.statusCode = 204;
      } else if (req.uri.path == '/control') {
        req.response.headers.contentType = ContentType.json;
        req.response.write(jsonEncode({'pause': pauseControl}));
      } else if (req.uri.path == '/clip.mp4') {
        videoFileRequests++;
        req.response.headers.contentType = ContentType('video', 'mp4');
        req.response.add(video);
      } else if (req.uri.path == '/') {
        alertPageLoads++;
        req.response.headers.contentType = ContentType.html;
        req.response.write(
          r'''<!doctype html><html><body style="background:black;color:white"><video id="video" autoplay loop playsinline src="/clip.mp4" width="128" height="72"></video><script>
const v=document.querySelector('video');v.volume=.1;v.play().catch(()=>{});
setInterval(()=>fetch('/tick?time='+v.currentTime+'&paused='+v.paused+'&ready='+v.readyState).catch(()=>{}),100);
let command=false;setInterval(()=>fetch('/control').then(r=>r.json()).then(c=>{if(c.pause!==command){command=c.pause;if(command)v.pause();else v.play().catch(()=>{});}}).catch(()=>{}),100);
</script></body></html>''',
        );
      } else {
        req.response.statusCode = 404;
      }
      await req.response.close();
    });
    final engine = SystemTtsEngine();
    final keepAliveErrors = <Object>[];
    final keepAlive = SpeakerKeepAlive(
      onError: (error, _) => keepAliveErrors.add(error),
    );
    addTearDown(() async {
      await keepAlive.dispose();
      await engine.dispose();
      await AudioChannel.set([]);
      await service.invokeMethod('stop');
      await server.close(force: true);
    });
    expect(await AudioChannel.set(['http://127.0.0.1:${server.port}/']), true);
    final startDeadline = DateTime.now().add(const Duration(seconds: 30));
    while (samples
                .where((s) => s['ready'] >= 2 && s['paused'] == false)
                .length <
            6 &&
        DateTime.now().isBefore(startDeadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect(
      samples.where((s) => s['paused'] == false),
      isNotEmpty,
      reason: 'The fixture must really be playing, not merely loaded.',
    );
    final speechStart = DateTime.now().millisecondsSinceEpoch;
    for (var n = 0; n < 6; n++) {
      // Repeating source synchronization must not reload the alert page.
      await AudioChannel.set(['http://127.0.0.1:${server.port}/']);
      await keepAlive.ping();
      await engine
          .speak('Message number ${n + 1}. The video must keep playing.')
          .timeout(const Duration(seconds: 45));
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
    expect(
      during.where((s) => s['paused'] == true),
      isEmpty,
      reason: 'TTS interrupted the active video.',
    );
    expect(
      during.map((s) => s['time']).toSet().length,
      greaterThan(15),
      reason: 'Video time froze while speech played.',
    );
    expect(alertPageLoads, 1, reason: 'TTS/source sync reloaded the alert page.');
    expect(keepAliveErrors, isEmpty);
    final silenceStart = DateTime.now().millisecondsSinceEpoch;
    pauseControl = true;
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    final silenceEnd = DateTime.now().millisecondsSinceEpoch;
    pauseControl = false;
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    final report = {
      'realAndroid': true,
      'realSystemSpeechMessages': 6,
      'realSpeakerKeepAlivePings': 6,
      'audioPilotHz': 9971,
      'speechStartAt': speechStart,
      'speechEndAt': speechEnd,
      'controlSilenceStartAt': silenceStart,
      'controlSilenceEndAt': silenceEnd,
      'speechSeconds': (speechEnd - speechStart) / 1000,
      'videoSamplesDuringSpeech': during.length,
      'videoPausedDuringSpeech': false,
      'alertPageLoads': alertPageLoads,
      'videoFileRequests': videoFileRequests,
      'privateSoundAlertsUrlTested': false,
    };
    debugPrint('APPISHOWDRIVE_AUDIO_REPORT ${jsonEncode(report)}');
  }, timeout: const Timeout(Duration(minutes: 6)));
}
