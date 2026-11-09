import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

typedef PaintFetch = Future<dynamic> Function(String userId);

/// Selected public 7TV paint, resolved by the author's actual Twitch ID.
class ChatPaintModel extends ChangeNotifier {
  final PaintFetch fetch;
  final DateTime Function() now;
  ChatPaintModel({PaintFetch? fetch, DateTime Function()? clock})
    : fetch = fetch ?? download,
      now = clock ?? DateTime.now;
  final _cache = <String, ({Map<String, dynamic>? paint, DateTime expiry})>{};
  final _pending = <String>{};
  final _queue = Queue<String>();
  var _active = 0, _disposed = false;
  Map<String, dynamic>? paintFor(String id) => _cache[id]?.paint;
  static const query =
      r'''query($id:String!){users{userByConnection(platform:TWITCH,platformId:$id){style{activePaint{id name data{layers{opacity ty{__typename ... on PaintLayerTypeSingleColor{color{hex}} ... on PaintLayerTypeLinearGradient{angle repeating stops{at color{hex}}} ... on PaintLayerTypeRadialGradient{repeating shape stops{at color{hex}}} ... on PaintLayerTypeImage{images{url width height mime frameCount}}}} shadows{blur color{hex} offsetX offsetY}}}}}}}''';
  static Future<dynamic> download(String id) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.postUrl(Uri.https('7tv.io', '/v4/gql'));
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'query': query,
          'variables': {'id': id},
        }),
      );
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode != 200) {
        throw const HttpException('7TV non disponibile');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 10))) {
        bytes.addAll(chunk);
        if (bytes.length > 256 * 1024) {
          throw const FormatException('7TV response too large');
        }
      }
      return jsonDecode(utf8.decode(bytes));
    } finally {
      client.close(force: true);
    }
  }

  static Map<String, dynamic>? parse(dynamic json) {
    if (json is! Map || json['errors'] != null) return null;
    final user = json['data']?['users']?['userByConnection'];
    final style = user is Map ? user['style'] : null;
    final paint = style is Map ? style['activePaint'] : null;
    return paint is Map && paint['data'] is Map
        ? Map<String, dynamic>.from(paint)
        : null;
  }

  void ensure(String id) {
    if (_disposed ||
        !RegExp(r'^\d+$').hasMatch(id) ||
        _pending.contains(id) ||
        _queue.length >= 200 ||
        (_cache[id]?.expiry.isAfter(now()) ?? false)) {
      return;
    }
    _pending.add(id);
    _queue.add(id);
    _pump();
  }

  void _pump() {
    while (!_disposed && _active < 2 && _queue.isNotEmpty) {
      final id = _queue.removeFirst();
      _active++;
      unawaited(
        _load(id).whenComplete(() {
          _active--;
          _pending.remove(id);
          _pump();
        }),
      );
    }
  }

  Future<void> _load(String id) async {
    Map<String, dynamic>? paint;
    var ttl = const Duration(minutes: 15);
    try {
      final result = await fetch(id);
      if (result is Map && result['errors'] != null) {
        throw const FormatException('7TV query rejected');
      }
      paint = parse(result);
    } catch (_) {
      ttl = const Duration(minutes: 2);
    }
    if (_disposed) return;
    if (_cache.length >= 2000) _cache.remove(_cache.keys.first);
    _cache[id] = (paint: paint, expiry: now().add(ttl));
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _queue.clear();
    super.dispose();
  }
}
