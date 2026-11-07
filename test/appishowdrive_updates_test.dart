import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/appishowdrive_updates.dart';

Map<String, dynamic> release({int build = 2}) => {
  'schema': 1,
  'package': 'com.ishowdrive.chat',
  'version': '1.0.1',
  'build': build,
  'url':
      'https://github.com/Whis1/appishowdrive-android/releases/download/android-v1.0.1/APPISHOWDRIVE.apk',
  'sha256': 'a' * 64,
  'bytes': 10000,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.ishowdrive.chat/updates-test');
  final calls = <MethodCall>[];
  String installResult = 'installer';
  bool failDownload = false;
  bool mediaActive = false;
  setUp(() {
    calls.clear();
    installResult = 'installer';
    failDownload = false;
    mediaActive = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'installed') {
            return {
              'build': 1,
              'package': 'com.ishowdrive.chat',
              'mediaActive': mediaActive,
            };
          }
          if (call.method == 'download') {
            if (failDownload) {
              throw PlatformException(
                code: 'bad_signature',
                message: 'Firma diversa',
              );
            }
            return true;
          }
          if (call.method == 'install') return installResult;
          return null;
        });
  });
  test('Android release accepts the intended APK only', () {
    final r = AndroidRelease.parse(release());
    expect(r.build, 2);
    expect(r.nativeArguments['sha256'], 'a' * 64);
  });
  test(
    'Android release rejects another app, external URL, downgrade metadata and malformed digests',
    () {
      for (final edit in [
        {'schema': 2},
        {'package': 'com.rtirl.chat'},
        {'url': 'http://github.com/file.apk'},
        {
          'url':
              'https://github.com/attacker/fork/releases/download/v1/file.apk',
        },
        {'sha256': 'bad'},
        {'bytes': 0},
        {'bytes': 9999999999},
        {'build': 0},
        {'build': 1.5},
        {'version': 'version2'},
      ]) {
        expect(
          () => AndroidRelease.parse({...release(), ...edit}),
          throwsFormatException,
        );
      }
    },
  );
  test('No download or installer for the current version', () async {
    final m = AndroidUpdates(
      channel: channel,
      fetchRelease: () async => release(build: 1),
    );
    await m.check();
    expect(m.phase, AndroidUpdatePhase.current);
    expect(calls.map((c) => c.method), ['installed']);
    m.dispose();
  });
  test(
    'A live audio session defers the automatic download until the user chooses it',
    () async {
      mediaActive = true;
      final m = AndroidUpdates(
        channel: channel,
        fetchRelease: () async => release(),
      );
      await m.check();
      expect(m.phase, AndroidUpdatePhase.available);
      expect(calls.map((c) => c.method), ['installed']);
      await m.download();
      expect(m.phase, AndroidUpdatePhase.ready);
      expect(calls.last.method, 'download');
      m.dispose();
    },
  );
  test(
    'Audio that starts while the release feed loads also defers the download',
    () async {
      final m = AndroidUpdates(
        channel: channel,
        fetchRelease: () async {
          mediaActive = true;
          return release();
        },
      );
      await m.check();
      expect(m.phase, AndroidUpdatePhase.available);
      expect(calls.any((c) => c.method == 'download'), false);
      m.dispose();
    },
  );
  test(
    'Launch downloads once, validates metadata and waits for the user before installing',
    () async {
      final m = AndroidUpdates(
        channel: channel,
        fetchRelease: () async => release(),
      );
      await m.check();
      expect(m.phase, AndroidUpdatePhase.ready);
      expect(m.progress, 1);
      expect(calls.map((c) => c.method), [
        'installed',
        'installed',
        'download',
      ]);
      expect(
        calls.last.arguments,
        AndroidRelease.parse(release()).nativeArguments,
      );
      await m.check();
      expect(calls.length, 3);
      await m.install();
      expect(calls.last.method, 'install');
      expect(m.phase, AndroidUpdatePhase.installer);
      m.dispose();
    },
  );
  test('Android install permission remains a user action', () async {
    installResult = 'permission';
    final m = AndroidUpdates(
      channel: channel,
      fetchRelease: () async => release(),
    );
    await m.check();
    await m.install();
    expect(m.phase, AndroidUpdatePhase.permission);
    await m.check();
    expect(calls.where((c) => c.method == 'install').length, 1);
    m.dispose();
  });
  test(
    'Failed signature cannot proceed automatically to the installer',
    () async {
      failDownload = true;
      final m = AndroidUpdates(
        channel: channel,
        fetchRelease: () async => release(),
      );
      await m.check();
      expect(m.phase, AndroidUpdatePhase.failed);
      expect(m.error, 'Firma diversa');
      expect(calls.any((c) => c.method == 'install'), false);
      m.dispose();
    },
  );
  test(
    'Offline checks keep chat available and do not repeatedly check on OAuth resumes',
    () async {
      var fetched = 0;
      final m = AndroidUpdates(
        channel: channel,
        fetchRelease: () async {
          fetched++;
          throw const FormatException();
        },
      );
      await m.check();
      expect(m.phase, AndroidUpdatePhase.failed);
      await m.check();
      expect(fetched, 1);
      await m.check(manual: true);
      expect(fetched, 2);
      m.dispose();
    },
  );
}
