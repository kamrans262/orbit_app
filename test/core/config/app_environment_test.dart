import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/config/app_environment.dart';

void main() {
  test('production environment requires HTTPS', () {
    expect(
      () => AppEnvironment.fromValues(
        name: 'production',
        apiBaseUrl: 'http://api.example.com/api',
        isRelease: false,
      ),
      throwsStateError,
    );
  });

  test('local development may use the Android emulator host bridge', () {
    final environment = AppEnvironment.fromValues(
      name: 'local',
      apiBaseUrl: 'http://10.0.2.2:8000/api/',
      isRelease: false,
    );

    expect(environment.apiBaseUrl, 'http://10.0.2.2:8000/api');
  });
}
