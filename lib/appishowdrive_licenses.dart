// APPISHOWDRIVE community modifications, 7 November 2026.
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

void registerCommunityLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'RealtimeChat · Muxable',
    ], await rootBundle.loadString('assets/rtchat-LICENSE.txt'));
    yield LicenseEntryWithLineBreaks([
      'APPISHOWDRIVE community edition',
    ], await rootBundle.loadString('assets/APPISHOWDRIVE-NOTICE.txt'));
  });
}
