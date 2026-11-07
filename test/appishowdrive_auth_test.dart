import 'package:flutter_test/flutter_test.dart';
import 'package:rtchat/components/auth/companion_auth.dart';

void main() {
  const session = 'a0b1c2d3-1234-4567-8901-123456789abc';
  test(
    'Both providers use the original supported device flow without a colliding app callback',
    () {
      for (final provider in ['twitch', 'kick']) {
        final uri = companionSignInUri(provider, session);
        expect(uri.scheme, 'https');
        expect(uri.host, 'chat.rtirl.com');
        expect(uri.path, '/auth/$provider/redirect');
        expect(uri.queryParameters['companion'], session);
        expect(uri.queryParameters.containsKey('token'), false);
      }
    },
  );
  test(
    'Unknown providers and malformed sessions cannot create login links',
    () {
      expect(
        () => companionSignInUri('../attacker', session),
        throwsArgumentError,
      );
      expect(
        () => companionSignInUri('kick', '?redirect=attacker'),
        throwsArgumentError,
      );
    },
  );
}
