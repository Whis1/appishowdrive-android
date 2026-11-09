import 'dart:core';

import 'package:flutter/material.dart';
import 'package:rtchat/models/messages/chat.dart';

Color darken(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslDark = hsl.withLightness((hsl.lightness) * (1 - amount));

  return hslDark.toColor();
}

Color lighten(Color color, [double amount = .1]) {
  assert(amount >= 0 && amount <= 1);

  final hsl = HSLColor.fromColor(color);
  final hslLight = hsl.withLightness((hsl.lightness) * (1 - amount) + amount);

  return hslLight.toColor();
}

enum CompactMessages { none, withinMessage, acrossMessages }

extension CompactMessagesJson on CompactMessages {
  static CompactMessages fromJson(dynamic value) {
    switch (value) {
      case 0:
        return CompactMessages.none;
      case 1:
        return CompactMessages.withinMessage;
      case 2:
        return CompactMessages.acrossMessages;
      default:
        return CompactMessages.none;
    }
  }

  int toJson() {
    switch (this) {
      case CompactMessages.none:
        return 0;
      case CompactMessages.withinMessage:
        return 1;
      case CompactMessages.acrossMessages:
        return 2;
    }
  }
}

class StyleModel extends ChangeNotifier {
  double _fontSize = 24;
  double _lightnessBoost = 0.179;
  bool _isDeletedMessagesVisible = true;
  CompactMessages _compactMessages = CompactMessages.none;
  bool _isDiscoModeAvailable = false;
  bool _isLoginShown = false;
  final Set<String> _hiddenBadgeProviders = {};
  bool badgesVisible(String provider) =>
      !_hiddenBadgeProviders.contains(provider);
  void hideBadges(String provider, bool hidden) {
    if (hidden) {
      _hiddenBadgeProviders.add(provider);
    } else {
      _hiddenBadgeProviders.remove(provider);
    }
    notifyListeners();
  }

  double get fontSize {
    return _fontSize;
  }

  set fontSize(double fontSize) {
    _fontSize = fontSize;
    notifyListeners();
  }

  double get lightnessBoost => _lightnessBoost;

  set lightnessBoost(double lightnessBoost) {
    _lightnessBoost = lightnessBoost;
    notifyListeners();
  }

  Color applyLightnessBoost(BuildContext context, Color color) {
    final theme = Theme.of(context), dark = theme.brightness == Brightness.dark;
    // Preserve the existing treatment of every colour except pure Twitch black.
    if ((color.toARGB32() & 0x00ffffff) != 0 || !dark) {
      return dark
          ? lighten(color, lightnessBoost)
          : darken(color, lightnessBoost);
    }
    final backgrounds = [
      theme.scaffoldBackgroundColor,
      theme.colorScheme.surface,
      Color.alphaBlend(
        theme.colorScheme.primary.withValues(alpha: .035),
        theme.colorScheme.surface,
      ),
    ];
    double contrast(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return ((x > y ? x : y) + .05) / ((x < y ? x : y) + .05);
    }

    final hsl = HSLColor.fromColor(theme.colorScheme.onSurface);
    var candidate = hsl.toColor();
    if (backgrounds.every((b) => contrast(candidate, b) >= 4.5)) {
      return candidate;
    }
    final target = dark ? 1.0 : 0.0;
    var low = 0.0, high = 1.0;
    for (var i = 0; i < 18; i++) {
      final fraction = (low + high) / 2;
      candidate =
          hsl
              .withLightness(
                hsl.lightness + (target - hsl.lightness) * fraction,
              )
              .toColor();
      if (backgrounds.every((b) => contrast(candidate, b) >= 4.5)) {
        high = fraction;
      } else {
        low = fraction;
      }
    }
    return hsl
        .withLightness(hsl.lightness + (target - hsl.lightness) * high)
        .toColor();
  }

  set isDeletedMessagesVisible(bool isDeletedMessagesVisible) {
    _isDeletedMessagesVisible = isDeletedMessagesVisible;
    notifyListeners();
  }

  bool get isDeletedMessagesVisible => _isDeletedMessagesVisible;

  set compactMessages(CompactMessages compactMessages) {
    _compactMessages = compactMessages;
    notifyListeners();
  }

  CompactMessages get compactMessages => _compactMessages;

  set isDiscoModeAvailable(bool isDiscoModeAvailable) {
    _isDiscoModeAvailable = isDiscoModeAvailable;
    notifyListeners();
  }

  bool get isLoginShown => _isLoginShown;

  set isLoginShown(bool isLoginShown) {
    _isLoginShown = isLoginShown;
    notifyListeners();
  }

  String getDisplayName(ChatUser user) {
    if (isLoginShown) return user.login;
    final displayName = user.displayName?.trim();
    return displayName == null || displayName.isEmpty
        ? user.login
        : displayName;
  }

  bool get isDiscoModeAvailable => _isDiscoModeAvailable;

  StyleModel.fromJson(Map<String, dynamic> json) {
    if (json['hiddenBadgeProviders'] is List) {
      _hiddenBadgeProviders.addAll(
        (json['hiddenBadgeProviders'] as List).whereType<String>(),
      );
    }
    if (json['fontSize'] != null) {
      _fontSize = json['fontSize'];
      if (json['dashboardStyle'] != 1 && _fontSize == 20) _fontSize = 24;
    }
    if (json['lightnessBoost'] != null) {
      _lightnessBoost = json['lightnessBoost'];
    }
    if (json['isDeletedMessagesVisible'] != null) {
      _isDeletedMessagesVisible = json['isDeletedMessagesVisible'];
    }
    if (json['compactMessages'] != null) {
      _compactMessages = CompactMessagesJson.fromJson(json['compactMessages']);
    }
    if (json['isDiscoModeEnabled'] != null) {
      _isDiscoModeAvailable = json['isDiscoModeEnabled'];
    }
    if (json['singleUsername'] == 1 && json['isLoginShown'] != null) {
      _isLoginShown = json['isLoginShown'];
    }
  }

  Map<String, dynamic> toJson() => {
    'singleUsername': 1,
    "hiddenBadgeProviders": _hiddenBadgeProviders.toList(),
    "lightnessBoost": _lightnessBoost,
    "fontSize": _fontSize,
    "dashboardStyle": 1,
    "isDeletedMessagesVisible": _isDeletedMessagesVisible,
    "compactMessages": _compactMessages.toJson(),
    "isDiscoModeEnabled": _isDiscoModeAvailable,
    "isLoginShown": _isLoginShown,
  };
}
