import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

class PublicChatBadge {
  final String provider, title, url;
  const PublicChatBadge(this.provider, this.title, this.url);
}

typedef IdentityFetch = Future<dynamic> Function(Uri url);

/// Public service data only; no account tokens and no inferred pronouns.
class ChatIdentityModel extends ChangeNotifier {
  final IdentityFetch fetch;
  final DateTime Function() now;
  ChatIdentityModel({IdentityFetch? fetch, DateTime Function()? clock})
    : fetch = fetch ?? download,
      now = clock ?? DateTime.now;
  final Map<String, Map<String, List<PublicChatBadge>>> _badges = {};
  final Map<String, DateTime> _catalogExpiry = {};
  final Set<String> _loading = {};
  final Map<String, ({String? label, DateTime expires})> _pronouns = {};
  final Queue<({String id, String login})> _queue = Queue();
  final Set<String> _pending = {};
  Future<dynamic>? _pronounCatalog;
  int _active = 0;
  bool _disposed = false;
  static const sources = {
    'ffz': 'https://api.frankerfacez.com/v1/badges/ids',
    'bttv': 'https://api.betterttv.net/3/cached/badges',
    'chatterino': 'https://api.chatterino.com/badges',
  };
  static Future<dynamic> download(Uri url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 8);
    try {
      final request = await client.getUrl(url);
      request.headers.set('User-Agent', 'APPISHOWDRIVE');
      final response = await request.close().timeout(
        const Duration(seconds: 10),
      );
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200) {
        throw HttpException('Identity service unavailable');
      }
      final bytes = <int>[];
      await for (final chunk in response.timeout(const Duration(seconds: 10))) {
        bytes.addAll(chunk);
        if (bytes.length > 2 * 1024 * 1024) {
          throw const FormatException('Identity response too large');
        }
      }
      return jsonDecode(utf8.decode(bytes));
    } finally {
      client.close(force: true);
    }
  }

  static String? imageUrl(dynamic value) {
    if (value is! String) return null;
    final url = Uri.tryParse(value.startsWith('//') ? 'https:$value' : value);
    return url != null && url.scheme == 'https' && url.host.isNotEmpty
        ? url.toString()
        : null;
  }

  static Map<String, List<PublicChatBadge>> parse(String source, dynamic json) {
    final users = <String, List<PublicChatBadge>>{};
    void add(dynamic user, PublicChatBadge badge) {
      final id = user.toString();
      if (RegExp(r'^\d+$').hasMatch(id)) (users[id] ??= []).add(badge);
    }

    if (source == 'bttv' && json is List) {
      for (final user in json.whereType<Map>()) {
        final b = user['badge'];
        if (b is! Map) continue;
        final url = imageUrl(b['svg'] ?? b['url']);
        if (url != null) {
          add(
            user['providerId'],
            PublicChatBadge(
              source,
              b['description']?.toString() ?? 'BetterTTV',
              url,
            ),
          );
        }
      }
    } else if (source == 'ffz' && json is Map) {
      final memberships = json['users'];
      for (final badge in (json['badges'] as List? ?? []).whereType<Map>()) {
        final urls = badge['urls'];
        final url = imageUrl(
          urls is Map ? urls['4'] ?? urls['2'] ?? urls['1'] : badge['image'],
        );
        if (url == null) continue;
        final memberIds =
            memberships is Map ? memberships[badge['id'].toString()] : null;
        for (final id in memberIds is List ? memberIds : []) {
          add(
            id,
            PublicChatBadge(
              source,
              badge['title']?.toString() ?? 'FrankerFaceZ',
              url,
            ),
          );
        }
      }
    } else if (source == 'chatterino' && json is Map) {
      for (final badge in (json['badges'] as List? ?? []).whereType<Map>()) {
        final url = imageUrl(
          badge['image3'] ?? badge['image2'] ?? badge['image1'],
        );
        if (url == null) continue;
        for (final id in badge['users'] is List ? badge['users'] : []) {
          add(
            id,
            PublicChatBadge(
              source,
              badge['tooltip']?.toString() ?? 'Chatterino',
              url,
            ),
          );
        }
      }
    }
    return users;
  }

  Future<void> ensureBadges(Iterable<String> visible) async {
    await Future.wait([
      for (final source in visible)
        if (sources.containsKey(source)) _ensureSource(source),
    ]);
  }

  Future<void> _ensureSource(String source) async {
    if (_disposed ||
        _loading.contains(source) ||
        (_catalogExpiry[source]?.isAfter(now()) ?? false)) {
      return;
    }
    _loading.add(source);
    try {
      final json = await fetch(Uri.parse(sources[source]!));
      if (_disposed) return;
      _badges[source] = parse(source, json);
      _catalogExpiry[source] = now().add(const Duration(hours: 6));
    } catch (_) {
      _catalogExpiry[source] = now().add(const Duration(minutes: 2));
    } finally {
      _loading.remove(source);
      if (!_disposed) notifyListeners();
    }
  }

  List<PublicChatBadge> badgesFor(String id, Iterable<String> visible) => [
    for (final provider in visible) ...?_badges[provider]?[id],
  ];
  String? pronounsFor(String id) => _pronouns[id]?.label;
  void ensurePronouns(String id, String login) {
    if (_disposed ||
        !RegExp(r'^\d+$').hasMatch(id) ||
        !RegExp(r'^[a-zA-Z0-9_]{1,25}$').hasMatch(login) ||
        _pending.contains(id) ||
        (_pronouns[id]?.expires.isAfter(now()) ?? false) ||
        _queue.length >= 200) {
      return;
    }
    _pending.add(id);
    _queue.add((id: id, login: login.toLowerCase()));
    _pump();
  }

  void _pump() {
    while (!_disposed && _active < 4 && _queue.isNotEmpty) {
      final user = _queue.removeFirst();
      _active++;
      unawaited(
        _loadPronouns(user.id, user.login).whenComplete(() {
          _active--;
          _pending.remove(user.id);
          _pump();
        }),
      );
    }
  }

  Future<void> _loadPronouns(String id, String login) async {
    try {
      final record = await fetch(
        Uri.https('api.pronouns.alejo.io', '/v1/users/$login'),
      );
      String? label;
      if (record is Map && record['channel_id'].toString() == id) {
        final catalog =
            await (_pronounCatalog ??= fetch(
              Uri.https('api.pronouns.alejo.io', '/v1/pronouns'),
            ));
        if (catalog is Map) {
          final main = catalog[record['pronoun_id']],
              alt = catalog[record['alt_pronoun_id']];
          if (main is Map &&
              main['subject'] is String &&
              main['object'] is String) {
            label =
                alt is Map && alt['subject'] is String
                    ? '${main['subject']}/${alt['subject']}'
                    : main['singular'] == true
                    ? main['subject']
                    : '${main['subject']}/${main['object']}';
          }
        }
      }
      if (!_disposed) {
        if (_pronouns.length >= 2000) _pronouns.remove(_pronouns.keys.first);
        _pronouns[id] = (
          label: label,
          expires: now().add(const Duration(hours: 1)),
        );
      }
    } catch (_) {
      _pronounCatalog = null;
      if (!_disposed) {
        _pronouns[id] = (
          label: null,
          expires: now().add(const Duration(minutes: 2)),
        );
      }
    }
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _queue.clear();
    super.dispose();
  }
}
