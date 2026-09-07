import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/push/domain/orbit_firebase_environment.dart';

void main() {
  test(
    'disabled Firebase environment does not require provider configuration',
    () {
      const environment = OrbitFirebaseEnvironment(
        enabled: false,
        projectId: '',
        messagingSenderId: '',
        androidApiKey: '',
        androidAppId: '',
        iosApiKey: '',
        iosAppId: '',
        iosBundleId: '',
      );

      expect(environment.enabled, isFalse);
    },
  );
}
