import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/messaging/domain/messaging_models.dart';

void main() {
  test(
    'encrypted sync envelope parser preserves opaque ciphertext metadata',
    () {
      final envelope = EncryptedInboundEnvelope.fromJson(<String, Object?>{
        'server_cursor': 14,
        'envelope_id': 'envelope-id',
        'message_id': 'message-id',
        'circle_id': 'circle-id',
        'sender_user_id': 4,
        'sender_device_id': 'sender-device-id',
        'recipient_device_id': 'recipient-device-id',
        'type': 'text',
        'ciphertext': 'opaque',
        'encrypted_preview': null,
        'created_at': '2026-09-06T01:00:00Z',
        'expires_at': '2026-10-06T01:00:00Z',
      });

      expect(envelope.serverCursor, 14);
      expect(envelope.type, OrbitMessageType.text);
      expect(envelope.ciphertext, 'opaque');
      expect(envelope.senderUserId, 4);
    },
  );

  test('unknown message types fail closed', () {
    expect(
      () => OrbitMessageType.parse('future_type'),
      throwsA(isA<FormatException>()),
    );
  });
}
