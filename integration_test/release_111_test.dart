import 'package:integration_test/integration_test.dart';
import 'identity_mascot_test.dart' as identity;
import 'appishowdrive_audio_test.dart' as audio;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  identity.main();
  audio.main();
}
