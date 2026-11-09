import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

Color paintColor(dynamic value) {
  final hex = value is Map ? value['hex'] : null;
  if (hex is! String || !RegExp(r'^#[0-9a-fA-F]{8}$').hasMatch(hex)) {
    return Colors.white;
  }
  final rgba = int.parse(hex.substring(1), radix: 16);
  return Color(((rgba & 255) << 24) | (rgba >> 8));
}

class NicknamePaint extends StatelessWidget {
  final String text;
  final TextStyle style;
  final Map<String, dynamic> paint;
  const NicknamePaint({
    super.key,
    required this.text,
    required this.style,
    required this.paint,
  });
  @override
  Widget build(BuildContext context) {
    final data = paint['data'] as Map;
    final shadows =
        (data['shadows'] as List? ?? [])
            .whereType<Map>()
            .take(4)
            .map(
              (s) => Shadow(
                color: paintColor(s['color']),
                blurRadius: ((s['blur'] as num?)?.toDouble() ?? 0).clamp(0, 8),
                offset: Offset(
                  ((s['offsetX'] as num?)?.toDouble() ?? 0).clamp(-4, 4),
                  ((s['offsetY'] as num?)?.toDouble() ?? 0).clamp(-4, 4),
                ),
              ),
            )
            .toList();
    final layers =
        (data['layers'] as List? ?? []).whereType<Map>().take(6).toList();
    Widget name({Color? color}) => Text(
      text,
      style: style.copyWith(color: color ?? style.color, shadows: shadows),
      textScaler: TextScaler.noScaling,
    );
    return Tooltip(
      message: '7TV · ${paint['name'] ?? ''}',
      child: Stack(
        children: [
          name(),
          for (final layer in layers)
            Opacity(
              opacity: ((layer['opacity'] as num?)?.toDouble() ?? 1).clamp(
                0,
                1,
              ),
              child: _layer(layer['ty'], name(color: Colors.white)),
            ),
        ],
      ),
    );
  }

  Widget _layer(dynamic type, Widget child) {
    if (type is! Map) return const SizedBox.shrink();
    if (type['__typename'] == 'PaintLayerTypeImage') {
      final images =
          (type['images'] as List? ?? [])
              .whereType<Map>()
              .where(
                (i) =>
                    i['url'] is String &&
                    Uri.tryParse(i['url'])?.scheme == 'https' &&
                    i['mime'] == 'image/webp',
              )
              .toList();
      images.sort(
        (a, b) => ((a['url'] as String).contains('_static') ? 100000 : 0)
            .compareTo((b['url'] as String).contains('_static') ? 100000 : 0),
      );
      if (images.isEmpty) return const SizedBox.shrink();
      return _ImagePaint(url: images.first['url'], child: child);
    }
    final stops =
        (type['stops'] as List? ?? []).whereType<Map>().toList()
          ..sort((a, b) => (a['at'] as num).compareTo(b['at'] as num));
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) {
        if (stops.length < 2) {
          final color = paintColor(type['color']);
          return ui.Gradient.linear(rect.topLeft, rect.bottomRight, [
            color,
            color,
          ]);
        }
        final colors = stops.map((s) => paintColor(s['color'])).toList();
        final offsets =
            stops
                .map((s) => (s['at'] as num).toDouble().clamp(0.0, 1.0))
                .toList();
        final tile =
            type['repeating'] == true ? TileMode.repeated : TileMode.clamp;
        if (type['__typename'] == 'PaintLayerTypeRadialGradient') {
          return ui.Gradient.radial(
            rect.center,
            math.max(rect.width, rect.height) / 2,
            colors,
            offsets,
            tile,
          );
        }
        final angle =
            (((type['angle'] as num?)?.toDouble() ?? 90) - 90) * math.pi / 180;
        final delta = Offset(
          math.cos(angle) * rect.width / 2,
          math.sin(angle) * rect.height / 2,
        );
        return ui.Gradient.linear(
          rect.center - delta,
          rect.center + delta,
          colors,
          offsets,
          tile,
        );
      },
      child: child,
    );
  }
}

class _ImagePaint extends StatefulWidget {
  final String url;
  final Widget child;
  const _ImagePaint({required this.url, required this.child});
  @override
  State<_ImagePaint> createState() => _ImagePaintState();
}

class _ImagePaintState extends State<_ImagePaint> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final _listener = ImageStreamListener((info, _) {
    final old = _info;
    if (mounted) {
      setState(() => _info = info);
    } else {
      info.dispose();
    }
    old?.dispose();
  }, onError: (Object _, StackTrace? _) {});
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_ImagePaint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) _resolve();
  }

  void _resolve() {
    _stream?.removeListener(_listener);
    _stream = CachedNetworkImageProvider(
      widget.url,
    ).resolve(createLocalImageConfiguration(context));
    _stream!.addListener(_listener);
  }

  @override
  Widget build(BuildContext context) {
    final image = _info?.image;
    if (image == null) return const SizedBox.shrink();
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) {
        final scale = rect.height / image.height;
        final matrix = Matrix4.diagonal3Values(scale, scale, 1)
          ..setTranslationRaw(rect.left, rect.top, 0);
        return ui.ImageShader(
          image,
          TileMode.repeated,
          TileMode.repeated,
          matrix.storage,
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }
}
