import 'dart:io';
import 'package:flutter/services.dart';
import 'package:on_device_tts/on_device_tts.dart';

/// The model is bundled in the APK; synthesis runs in a separate Android process.
class EmbeddedItalianEngine extends TtsEngine {
  static const channel = MethodChannel('com.ishowdrive.chat/embedded-speech');
  static const names = {
    'F1': 'Sara · femminile 1',
    'F2': 'Alba · femminile 2',
    'F3': 'Emma · femminile 3',
    'F4': 'Dora · femminile 4',
    'F5': 'Luna · femminile 5',
    'M1': 'Nicola · maschile 1',
    'M2': 'Adamo · maschile 2',
    'M3': 'Giorgio · maschile 3',
    'M4': 'Alessio · maschile 4',
    'M5': 'Luca · maschile 5',
  };
  bool _disposed = false;
  @override
  Future<List<TtsVoice>> voices({String? language}) async =>
      _disposed ||
              (language != null && !language.toLowerCase().startsWith('it'))
          ? []
          : [
            for (final voice in names.entries)
              TtsVoice(id: voice.key, name: voice.value, locale: 'it-IT'),
          ];
  @override
  Future<void> speak(
    String text, {
    TtsVoice? voice,
    double rate = .5,
    double pitch = 1,
    String? language,
  }) async {
    if (_disposed || !Platform.isAndroid) {
      throw StateError('Motore vocale non disponibile.');
    }
    try {
      await channel.invokeMethod<void>('speak', {
        'text': text,
        'voice': voice?.id ?? 'F1',
        'rate': rate,
        'pitch': pitch,
      });
    } on PlatformException catch (error) {
      throw NeuralTtsLoadException(error);
    }
  }

  @override
  Future<void> stop() async {
    if (!_disposed) await channel.invokeMethod<void>('stop');
  }

  @override
  Future<void> release() async {
    if (!_disposed) await channel.invokeMethod<void>('release');
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    await release();
    _disposed = true;
  }
}
