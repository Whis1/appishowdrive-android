import 'dart:async';
import 'dart:core';

import 'package:flutter/foundation.dart';
import 'package:rtchat/models/adapters/chat_state.dart';
import 'package:rtchat/models/channels.dart';

class TwitchBadgeModel extends ChangeNotifier {
  StreamSubscription<void>? _globalBadgeSubscription;
  StreamSubscription<void>? _localBadgeSubscription;

  List<TwitchBadgeInfo> localBadgeSets = [];
  List<TwitchBadgeInfo> globalBadgeSets = [];
  Set<String> _enabled = {};
  bool _isAllEnabled = true;
  Channel? _channel;
  var _generation = 0;
  bool _disposed = false;

  set channel(Channel? channel) {
    if (_channel == channel && _globalBadgeSubscription != null) return;
    _channel = channel;
    final generation = ++_generation;
    localBadgeSets.clear();
    globalBadgeSets.clear();
    _globalBadgeSubscription?.cancel();
    _localBadgeSubscription?.cancel();

    _globalBadgeSubscription = ChatStateAdapter.instance
        .getTwitchBadges()
        .asStream()
        .listen((badgeSets) {
          if (_disposed || generation != _generation) return;
          globalBadgeSets = badgeSets;
          notifyListeners();
        }, onError: (Object _) {});
    if (channel != null) {
      if (channel.provider != Providers.twitch) {
        return;
      }
      _localBadgeSubscription = ChatStateAdapter.instance
          .getTwitchBadges(channelId: channel.channelId)
          .asStream()
          .listen((badgeSets) {
            if (_disposed || generation != _generation) return;
            localBadgeSets = badgeSets;
            notifyListeners();
          }, onError: (Object _) {});
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _globalBadgeSubscription?.cancel();
    _localBadgeSubscription?.cancel();
    super.dispose();
  }

  List<TwitchBadgeInfo> get badgeSets {
    return [...localBadgeSets, ...globalBadgeSets];
  }

  void setAllEnabled(bool enabled) {
    if (enabled) {
      _enabled = badgeSets.map((e) => e.setId).toSet();
      _isAllEnabled = true;
    } else {
      _enabled.clear();
      _isAllEnabled = false;
    }

    notifyListeners();
  }

  void setEnabled(String key, bool enabled) {
    if (_isAllEnabled) _enabled = badgeSets.map((e) => e.setId).toSet();
    if (enabled) {
      _enabled.add(key);
    } else {
      _enabled.remove(key);
    }
    if (_enabled.length == badgeCount && badgeCount > 0) {
      _isAllEnabled = true;
    } else {
      _isAllEnabled = false;
    }

    notifyListeners();
  }

  bool isEnabled(String setId) => _enabled.contains(setId) || _isAllEnabled;

  int get badgeCount {
    final globalKeys = globalBadgeSets.map((e) => e.setId).toSet();
    final localKeys = localBadgeSets.map((e) => e.setId).toSet();
    return globalKeys.union(localKeys).length;
  }

  int get enabledCount => _isAllEnabled ? badgeCount : _enabled.length;

  TwitchBadgeModel.fromJson(Map<String, dynamic> json) {
    final badges = json['enabled'];
    _isAllEnabled =
        json['schema'] == 2
            ? json['allEnabled'] == true
            : badges is! List || badges.isEmpty;
    if (badges is List) {
      for (final badge in badges.whereType<String>()) {
        _enabled.add(badge);
      }
      notifyListeners();
    }
  }

  Map<String, dynamic> toJson() => {
    "enabled": _enabled.toList(),
    "allEnabled": _isAllEnabled,
    "schema": 2,
  };
}
