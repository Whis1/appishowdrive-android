// APPISHOWDRIVE community modifications, 7 November 2026.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerCommunityLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'RealtimeChat · Muxable',
    ], await rootBundle.loadString('assets/rtchat-LICENSE.txt'));
    yield LicenseEntryWithLineBreaks([
      'Kokoro · profili italiani integrati',
      'MediaPipe / LiteRT-LM',
    ], await rootBundle.loadString('assets/KOKORO-LICENSE.txt'));
    yield LicenseEntryWithLineBreaks([
      'Kokoro · attribuzioni e modifiche',
    ], await rootBundle.loadString('assets/KOKORO-NOTICE.txt'));
    for (final font in ['Manrope', 'SpaceGrotesk']) {
      yield LicenseEntryWithLineBreaks([
        font,
      ], await rootBundle.loadString('assets/fonts/$font-OFL.txt'));
    }
    yield LicenseEntryWithLineBreaks([
      'APPISHOWDRIVE community edition',
    ], await rootBundle.loadString('assets/APPISHOWDRIVE-NOTICE.txt'));
  });
}
