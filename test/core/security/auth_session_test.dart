import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/security/auth_session.dart';

void main() {
  test('identity pair preserves device binding and refresh window', () {
    final now = DateTime.utc(2026, 9, 6, 12);
    final session = AuthSession.fromIdentityPair(<String, Object?>{
      'access_token': 'access-token',
      'access_expires_at': now
          .add(const Duration(minutes: 15))
          .toIso8601String(),
      'refresh_token': 'refresh-token',
      'refresh_expires_at': now.add(const Duration(days: 60)).toIso8601String(),
      'session_id': 'session-1',
    }, deviceId: 'device-1');

    expect(session.deviceId, 'device-1');
    expect(session.shouldRefresh(now: now), isFalse);
    expect(
      session.shouldRefresh(
        now: now.add(const Duration(minutes: 14, seconds: 30)),
      ),
      isTrue,
    );
    expect(
      session.refreshExpired(now: now.add(const Duration(days: 59))),
      isFalse,
    );
  });
}
