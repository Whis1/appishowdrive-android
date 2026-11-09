import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rtchat/models/layout.dart';
import 'package:rtchat/models/user.dart';
import 'package:rtchat/models/views.dart';

/// Kept by the root host, never by a page or an app-resume callback.
class WelcomeSession {
  bool consumed = false;
  bool claim({required bool signedIn, required bool enabled}) {
    if (consumed || !signedIn) return false;
    consumed = true;
    return enabled;
  }
}

class WelcomeMascotHost extends StatefulWidget {
  final Widget child;
  const WelcomeMascotHost({super.key, required this.child});
  @override
  State<WelcomeMascotHost> createState() => _WelcomeMascotHostState();
}

class _WelcomeMascotHostState extends State<WelcomeMascotHost>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _session = WelcomeSession();
  final _player = AudioPlayer();
  final _clock = Stopwatch();
  final _subscriptions = <StreamSubscription<dynamic>>[];
  late final Ticker _ticker;
  ui.Image? _body, _face, _smile;
  List<dynamic> _cues = [];
  Duration _anchor = Duration.zero;
  Timer? _hold, _hide;
  bool _visible = false, _fading = false, _loading = false;
  bool _finished = false;
  AppLifecycleState _lifecycle = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((_) {
      if (mounted && _visible) setState(() {});
    });
    _subscriptions.add(
      _player.onPositionChanged.listen((position) {
        _anchor = position;
        _clock.reset();
      }),
    );
    _subscriptions.add(
      _player.onPlayerStateChanged.listen((state) {
        if (state == PlayerState.playing) {
          _clock.start();
        } else {
          _clock.stop();
        }
      }),
    );
    _subscriptions.add(
      _player.onPlayerComplete.listen((_) {
        if (!mounted) return;
        _clock.stop();
        _ticker.stop();
        setState(() {
          _cues = [];
          _finished = true;
        });
        _hold = Timer(const Duration(seconds: 2), _fade);
      }),
    );
  }

  void _fade() {
    if (!mounted || !_visible || _fading) return;
    setState(() => _fading = true);
    _hide?.cancel();
    _hide = Timer(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  Future<ui.Image> _image(String path) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  Future<void> _start() async {
    if (_loading || !mounted) return;
    _loading = true;
    ui.Image? body, face, smile;
    try {
      body = await _image('assets/welcome/emperor.png');
      face = await _image('assets/welcome/face.png');
      smile = await _image('assets/welcome/smile-atlas.png');
      final json =
          jsonDecode(await rootBundle.loadString('assets/welcome/cues.json'))
              as Map;
      if (!mounted ||
          _lifecycle != AppLifecycleState.resumed ||
          !context.read<LayoutModel>().welcomeMascot) {
        return;
      }
      _body = body;
      body = null;
      _face = face;
      face = null;
      _smile = smile;
      smile = null;
      _cues = json['mouthCues'] as List;
      await _player.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            audioFocus: AndroidAudioFocus.none,
            usageType: AndroidUsageType.media,
            contentType: AndroidContentType.speech,
          ),
        ),
      );
      if (!mounted || _lifecycle != AppLifecycleState.resumed) return;
      setState(() => _visible = true);
      _ticker.start();
      await _player.play(AssetSource('welcome/voice.mp3'));
    } catch (_) {
      if (!mounted) return;
      _ticker.stop();
      if (mounted) setState(() => _visible = false);
    } finally {
      body?.dispose();
      face?.dispose();
      smile?.dispose();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycle = state;
    if (state != AppLifecycleState.resumed && _visible) {
      unawaited(_player.stop());
      _ticker.stop();
      _hold?.cancel();
      if (mounted) setState(() => _visible = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = context.watch<LayoutModel>().welcomeMascot;
    final user = context.watch<UserModel>();
    final channel = context.watch<ViewsModel>().primaryChannel;
    if (_lifecycle == AppLifecycleState.resumed &&
        _session.claim(
          signedIn: !user.isLoading && user.isSignedIn() && channel != null,
          enabled: enabled,
        )) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _start());
    }
    if (!enabled && _visible && !_fading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(_player.stop());
          _fade();
        }
      });
    }
    final screen = MediaQuery.sizeOf(context);
    final height = (screen.height * .40).clamp(0.0, 360.0);
    final seconds = (_anchor + _clock.elapsed).inMilliseconds / 1000;
    final mouth =
        _finished
            ? 'smile'
            : _cues
                        .where(
                          (c) => seconds >= c['start'] && seconds < c['end'],
                        )
                        .firstOrNull?['value']
                    as String? ??
                'X';
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (_visible && _body != null && _face != null)
          Positioned(
            left: 4,
            bottom: MediaQuery.paddingOf(context).bottom + 4,
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: AnimatedOpacity(
                  opacity: _fading ? 0 : 1,
                  duration: const Duration(milliseconds: 600),
                  child: SizedBox(
                    width: height * 843 / 1264,
                    height: height,
                    child: CustomPaint(
                      painter: MascotPainter(
                        _body!,
                        _face!,
                        mouth,
                        smile: _smile,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hold?.cancel();
    _hide?.cancel();
    _ticker.dispose();
    for (final subscription in _subscriptions) {
      unawaited(subscription.cancel());
    }
    unawaited(_player.dispose());
    _body?.dispose();
    _face?.dispose();
    _smile?.dispose();
    super.dispose();
  }
}

class MascotPainter extends CustomPainter {
  final ui.Image body, face;
  final ui.Image? smile;
  final String mouth;
  MascotPainter(this.body, this.face, this.mouth, {this.smile});
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 843, size.height / 1264);
    final paint = Paint()..filterQuality = FilterQuality.medium;
    canvas.drawImageRect(
      body,
      Rect.fromLTWH(0, 0, body.width.toDouble(), body.height.toDouble()),
      const Rect.fromLTWH(0, 0, 843, 1264),
      paint,
    );
    final frame = switch (mouth) {
      'D' || 'E' => 0,
      'B' => 1,
      'C' => 2,
      'F' || 'H' => 3,
      'G' => 4,
      _ => -1,
    };
    if (frame >= 0) {
      canvas.drawImageRect(
        face,
        Rect.fromLTWH(frame * 60.0, 30, 48, 28),
        const Rect.fromLTWH(417, 229, 66, 36),
        paint,
      );
    }
    if (mouth == 'smile' && smile != null) {
      final cell = smile!.width / 3;
      const destination = Rect.fromLTWH(417, 229, 66, 36);
      canvas.saveLayer(destination, Paint());
      canvas.drawImageRect(
        smile!,
        Rect.fromLTWH(cell * 2.335, cell * 2.49, cell * .33, cell * .18),
        destination,
        paint,
      );
      canvas.drawRect(
        destination,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = ui.Gradient.radial(
            destination.center,
            destination.width / 2,
            [
              const Color(0xffffffff),
              const Color(0xffffffff),
              const Color(0x00ffffff),
            ],
            [0, .65, 1],
            TileMode.clamp,
            (Matrix4.diagonal3Values(
              1,
              destination.height / destination.width,
              1,
            )..setTranslationRaw(
              0,
              destination.center.dy *
                  (1 - destination.height / destination.width),
              0,
            )).storage,
          ),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(MascotPainter oldDelegate) =>
      oldDelegate.mouth != mouth ||
      oldDelegate.body != body ||
      oldDelegate.face != face ||
      oldDelegate.smile != smile;
}
