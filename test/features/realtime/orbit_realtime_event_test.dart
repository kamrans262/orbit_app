import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/realtime/domain/orbit_realtime_event.dart';

void main() {
  test('event helpers parse backend identifiers without exposing payloads', () {
    const event = OrbitRealtimeEvent(
      channel: 'private-circles.circle_1',
      name: 'typing.updated',
      data: <String, Object?>{'circle_id': 'circle_1', 'user_id': 42},
    );

    expect(event.stringValue('circle_id'), 'circle_1');
    expect(event.intValue('user_id'), 42);
  });

  test('delivery receipt exposes only the message identifier helper', () {
    const event = OrbitRealtimeEvent(
      channel: 'private-users.7',
      name: 'message.delivered',
      data: <String, Object?>{'message_id': 'message_1'},
    );

    expect(event.stringValue('message_id'), 'message_1');
  });
}
