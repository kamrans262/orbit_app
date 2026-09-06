import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/realtime/domain/realtime_environment.dart';

void main() {
  test('disabled Reverb configuration keeps polling fallback available', () {
    final environment = RealtimeEnvironment.fromValues(
      appKey: '',
      host: '127.0.0.1',
      port: 8080,
      scheme: 'ws',
      requireTls: false,
    );

    expect(environment.isEnabled, isFalse);
    expect(environment.socketUri.path, '/app/');
  });

  test('production realtime requires WSS', () {
    expect(
      () => RealtimeEnvironment.fromValues(
        appKey: 'key',
        host: 'reverb.example.com',
        port: 443,
        scheme: 'ws',
        requireTls: true,
      ),
      throwsStateError,
    );
  });

  test('Pusher protocol URI contains only non-secret connection metadata', () {
    final environment = RealtimeEnvironment.fromValues(
      appKey: 'public-app-key',
      host: 'reverb.example.com',
      port: 443,
      scheme: 'wss',
      requireTls: true,
    );

    expect(environment.socketUri.scheme, 'wss');
    expect(environment.socketUri.host, 'reverb.example.com');
    expect(environment.socketUri.queryParameters['protocol'], '7');
    expect(environment.socketUri.queryParameters.containsKey('token'), isFalse);
  });
}
