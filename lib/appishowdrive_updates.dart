import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const androidReleaseFeed =
    'https://github.com/Whis1/appishowdrive-android/releases/latest/download/android-update.json';
const _releasePrefix =
    'https://github.com/Whis1/appishowdrive-android/releases/download/';

class AndroidRelease {
  final String version, url, sha256;
  final int build, bytes;
  const AndroidRelease(
    this.version,
    this.build,
    this.url,
    this.sha256,
    this.bytes,
  );
  factory AndroidRelease.parse(Map<String, dynamic> value) {
    final version = value['version'],
        build = value['build'],
        url = value['url'],
        sha = value['sha256'],
        bytes = value['bytes'];
    if (value['schema'] != 1 ||
        value['package'] != 'com.ishowdrive.chat' ||
        version is! String ||
        !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version) ||
        build is! int ||
        build < 1 ||
        bytes is! int ||
        bytes < 1 ||
        bytes > 512 * 1024 * 1024 ||
        sha is! String ||
        !RegExp(r'^[a-f0-9]{64}$').hasMatch(sha) ||
        url is! String ||
        !url.startsWith(_releasePrefix) ||
        !url.endsWith('.apk')) {
      throw const FormatException('Dati aggiornamento non validi.');
    }
    return AndroidRelease(version, build, url, sha, bytes);
  }
  Map<String, dynamic> get nativeArguments => {
    'url': url,
    'sha256': sha256,
    'bytes': bytes,
    'build': build,
  };
}

enum AndroidUpdatePhase {
  idle,
  checking,
  current,
  available,
  downloading,
  ready,
  permission,
  installer,
  failed,
}

class AndroidUpdates extends ChangeNotifier {
  final MethodChannel channel;
  final Future<Map<String, dynamic>> Function() fetchRelease;
  AndroidUpdatePhase phase = AndroidUpdatePhase.idle;
  AndroidRelease? release;
  String? error;
  double progress = 0;
  bool explicitCheck = false;
  DateTime? _lastCheck;
  bool _checking = false;
  AndroidUpdates({
    this.channel = const MethodChannel('com.ishowdrive.chat/updates'),
    Future<Map<String, dynamic>> Function()? fetchRelease,
  }) : fetchRelease = fetchRelease ?? _fetch {
    channel.setMethodCallHandler((call) async {
      if (call.method == 'progress' &&
          phase == AndroidUpdatePhase.downloading &&
          call.arguments is num) {
        progress = (call.arguments as num).toDouble().clamp(0, 1);
        notifyListeners();
      }
    });
  }
  static Future<Map<String, dynamic>> _fetch() async {
    final client =
        HttpClient()..connectionTimeout = const Duration(seconds: 12);
    try {
      final req = await client.getUrl(Uri.parse(androidReleaseFeed));
      req.headers.set('User-Agent', 'APPISHOWDRIVE-Android');
      req.headers.set('Cache-Control', 'no-cache');
      final res = await req.close().timeout(const Duration(seconds: 15));
      if (res.statusCode != 200) {
        throw const HttpException('Controllo aggiornamenti non disponibile.');
      }
      final data = <int>[];
      await for (final chunk in res.timeout(const Duration(seconds: 15))) {
        data.addAll(chunk);
        if (data.length > 65536) {
          throw const FormatException('Risposta troppo grande.');
        }
      }
      final value = jsonDecode(utf8.decode(data));
      if (value is! Map<String, dynamic>) {
        throw const FormatException('Risposta non valida.');
      }
      return value;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> check({bool manual = false}) async {
    if (_checking ||
        phase == AndroidUpdatePhase.downloading ||
        phase == AndroidUpdatePhase.ready ||
        phase == AndroidUpdatePhase.permission ||
        phase == AndroidUpdatePhase.installer) {
      return;
    }
    if (!manual &&
        _lastCheck != null &&
        DateTime.now().difference(_lastCheck!) < const Duration(minutes: 10)) {
      return;
    }
    _checking = true;
    _lastCheck = DateTime.now();
    explicitCheck = manual;
    phase = AndroidUpdatePhase.checking;
    error = null;
    notifyListeners();
    try {
      final installed = await channel.invokeMapMethod<String, dynamic>(
        'installed',
      );
      if (installed?['package'] != 'com.ishowdrive.chat' ||
          installed?['build'] is! int) {
        throw const FormatException('Installazione non riconosciuta.');
      }
      final latest = AndroidRelease.parse(await fetchRelease());
      if (latest.build <= (installed!['build'] as int)) {
        phase = AndroidUpdatePhase.current;
        notifyListeners();
        return;
      }
      release = latest;
      phase = AndroidUpdatePhase.available;
      notifyListeners();
      // Do not automatically consume an IRL streamer's mobile connection
      // while their voice or alert sources are active.
      if (installed['mediaActive'] == true) return;
      // Sources may finish starting while the release feed is loading.
      final beforeDownload = await channel.invokeMapMethod<String, dynamic>(
        'installed',
      );
      if (beforeDownload?['mediaActive'] == true) return;
      await download();
    } catch (_) {
      phase = AndroidUpdatePhase.failed;
      error =
          'Impossibile controllare gli aggiornamenti. La chat resta disponibile.';
      notifyListeners();
    } finally {
      _checking = false;
    }
  }

  Future<void> download() async {
    if (release == null || phase == AndroidUpdatePhase.downloading) return;
    phase = AndroidUpdatePhase.downloading;
    progress = 0;
    error = null;
    notifyListeners();
    try {
      final ok = await channel.invokeMethod<bool>(
        'download',
        release!.nativeArguments,
      );
      if (ok != true) throw const FormatException('Download incompleto.');
      progress = 1;
      phase = AndroidUpdatePhase.ready;
    } on PlatformException catch (e) {
      error = e.message ?? 'Download non riuscito.';
      phase = AndroidUpdatePhase.failed;
    } catch (_) {
      error = 'Download non riuscito. Puoi riprovare.';
      phase = AndroidUpdatePhase.failed;
    }
    notifyListeners();
  }

  Future<void> install() async {
    try {
      final value = await channel.invokeMethod<String>('install');
      phase =
          value == 'permission'
              ? AndroidUpdatePhase.permission
              : AndroidUpdatePhase.installer;
    } on PlatformException catch (e) {
      error = e.message;
      phase = AndroidUpdatePhase.failed;
    }
    notifyListeners();
  }
}

final androidUpdates = AndroidUpdates();

class AppUpdateHost extends StatefulWidget {
  final Widget child;
  const AppUpdateHost({super.key, required this.child});
  @override
  State<AppUpdateHost> createState() => _AppUpdateHostState();
}

class _AppUpdateHostState extends State<AppUpdateHost>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addObserver(this);
      unawaited(androidUpdates.check());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && Platform.isAndroid) {
      unawaited(androidUpdates.check());
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: androidUpdates,
    builder: (context, _) {
      final phase = androidUpdates.phase;
      final visible =
          Platform.isAndroid &&
          (phase == AndroidUpdatePhase.checking ||
              phase == AndroidUpdatePhase.available ||
              phase == AndroidUpdatePhase.downloading ||
              phase == AndroidUpdatePhase.ready ||
              phase == AndroidUpdatePhase.permission);
      return Column(
        children: [
          if (visible)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainer,
              child: SafeArea(
                bottom: false,
                child: const UpdateStatus(compact: true),
              ),
            ),
          Expanded(child: widget.child),
        ],
      );
    },
  );
}

class UpdateStatus extends StatelessWidget {
  final bool compact;
  const UpdateStatus({super.key, this.compact = false});
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: androidUpdates,
    builder: (context, _) {
      final m = androidUpdates, p = m.phase;
      final text = switch (p) {
        AndroidUpdatePhase.available =>
          'Nuova versione disponibile · scarica al termine della live',
        AndroidUpdatePhase.checking => 'Controllo aggiornamenti…',
        AndroidUpdatePhase.downloading =>
          'Aggiornamento in download · ${(m.progress * 100).round()}%',
        AndroidUpdatePhase.ready =>
          'APPISHOWDRIVE ${m.release?.version} pronta da installare',
        AndroidUpdatePhase.permission =>
          'Autorizza APPISHOWDRIVE, poi premi Installa',
        AndroidUpdatePhase.installer =>
          'Completa l’installazione nella schermata Android',
        AndroidUpdatePhase.current => 'APPISHOWDRIVE è aggiornata',
        AndroidUpdatePhase.failed => m.error ?? 'Aggiornamento non disponibile',
        _ => 'Gli aggiornamenti vengono controllati all’apertura',
      };
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(text)),
                if (p == AndroidUpdatePhase.available)
                  TextButton(
                    onPressed: m.download,
                    child: const Text('Scarica'),
                  ),
                if ([
                  AndroidUpdatePhase.ready,
                  AndroidUpdatePhase.permission,
                  AndroidUpdatePhase.installer,
                ].contains(p))
                  TextButton(
                    onPressed: m.install,
                    child: const Text('Installa'),
                  ),
                if (!compact &&
                    ![
                      AndroidUpdatePhase.checking,
                      AndroidUpdatePhase.downloading,
                    ].contains(p))
                  TextButton(
                    onPressed: () => m.check(manual: true),
                    child: const Text('Controlla'),
                  ),
              ],
            ),
            if (p == AndroidUpdatePhase.downloading)
              LinearProgressIndicator(value: m.progress),
            if (!compact)
              const Text(
                'Durante TTS o sorgenti audio attivi, il download automatico aspetta. Puoi scaricare quando preferisci; installa al termine della live. Android chiederà conferma. Account e impostazioni vengono conservati.',
                style: TextStyle(fontSize: 13),
              ),
            if (!compact && p == AndroidUpdatePhase.failed && m.release != null)
              TextButton(
                onPressed: m.download,
                child: const Text('Riprova download'),
              ),
          ],
        ),
      );
    },
  );
}

class AppUpdatesScreen extends StatelessWidget {
  const AppUpdatesScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Aggiornamenti APPISHOWDRIVE')),
    body: const SafeArea(child: UpdateStatus()),
  );
}
