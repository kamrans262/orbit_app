import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/notifications/domain/orbit_notification.dart';

void main() {
  test('SOS notifications derive only the allowlisted internal SOS route', () {
    final notification = OrbitNotification(
      id: 'notification-1',
      kind: 'sos.activated',
      priority: 'highest',
      summary: 'Emergency SOS',
      payload: const <String, Object?>{'sos_id': 'sos id'},
      deepLink: 'https://untrusted.example/should-not-run',
      createdAt: DateTime(2026, 9, 6),
    );

    expect(notification.internalRoute, '/sos/sos%20id');
  });
}
