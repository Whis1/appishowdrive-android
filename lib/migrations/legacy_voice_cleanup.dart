import 'dart:io';

/// Removes only the app-owned model directories used by retired voice packs.
/// Chat preferences, audio sources, and authentication data are untouched.
Future<void> clearLegacyVoiceModelData(Directory applicationSupport) async {
  for (final name in const ['voice_packs', 'speech']) {
    final directory = Directory(
      '${applicationSupport.path}${Platform.pathSeparator}$name',
    );
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
