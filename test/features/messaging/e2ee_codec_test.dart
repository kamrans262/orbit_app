import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/messaging/data/orbit_e2ee_codec.dart';
import 'package:orbit_app/features/messaging/domain/e2ee_identity.dart';
import 'package:orbit_app/features/messaging/domain/messaging_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('text round-trips only with the intended recipient identity', () async {
    final codec = OrbitE2eeCodec();
    final sender = await _identity();
    final recipient = await _identity();
    final recipientDevice = MessageDevice(
      deviceId: '22222222-2222-4222-8222-222222222222',
      userId: 2,
      displayName: 'Recipient',
      platform: 'android',
      identity: recipient.publicIdentity,
    );

    final outbound = await codec.encryptText(
      envelopeId: '33333333-3333-4333-8333-333333333333',
      messageId: '44444444-4444-4444-8444-444444444444',
      circleId: '55555555-5555-4555-8555-555555555555',
      senderDeviceId: '11111111-1111-4111-8111-111111111111',
      recipient: recipientDevice,
      senderIdentity: sender,
      plaintext: 'Private hello',
    );

    final clear = await codec.decryptText(
      envelope: _inbound(outbound.ciphertext),
      recipientIdentity: recipient,
      senderIdentity: sender.publicIdentity,
    );

    expect(clear.body, 'Private hello');
  });

  test(
    'tampered ciphertext is rejected before plaintext is returned',
    () async {
      final codec = OrbitE2eeCodec();
      final sender = await _identity();
      final recipient = await _identity();
      final outbound = await codec.encryptText(
        envelopeId: '33333333-3333-4333-8333-333333333333',
        messageId: '44444444-4444-4444-8444-444444444444',
        circleId: '55555555-5555-4555-8555-555555555555',
        senderDeviceId: '11111111-1111-4111-8111-111111111111',
        recipient: MessageDevice(
          deviceId: '22222222-2222-4222-8222-222222222222',
          userId: 2,
          displayName: 'Recipient',
          platform: 'ios',
          identity: recipient.publicIdentity,
        ),
        senderIdentity: sender,
        plaintext: 'Do not tamper',
      );

      final wire = jsonDecode(outbound.ciphertext) as Map<String, dynamic>;
      final bytes = base64Url.decode(wire['ct']! as String);
      bytes[0] ^= 1;
      wire['ct'] = base64Url.encode(bytes);

      await expectLater(
        codec.decryptText(
          envelope: _inbound(jsonEncode(wire)),
          recipientIdentity: recipient,
          senderIdentity: sender.publicIdentity,
        ),
        throwsA(isA<OrbitE2eeException>()),
      );
    },
  );

  test(
    'public identity bundle round-trips through backend string field',
    () async {
      final identity = await _identity();
      final encoded = identity.publicIdentity.toServerValue();
      final decoded = DevicePublicIdentity.fromServerValue(encoded);

      expect(
        decoded.keyAgreementPublicKey,
        identity.publicIdentity.keyAgreementPublicKey,
      );
      expect(
        decoded.signingPublicKey,
        identity.publicIdentity.signingPublicKey,
      );
    },
  );
}

Future<DevicePrivateIdentity> _identity() async {
  final agreement = await (await X25519().newKeyPair()).extract();
  final signing = await (await Ed25519().newKeyPair()).extract();
  return DevicePrivateIdentity(
    keyAgreementKeyPair: agreement,
    signingKeyPair: signing,
    publicIdentity: DevicePublicIdentity(
      keyAgreementPublicKey: agreement.publicKey.bytes,
      signingPublicKey: signing.publicKey.bytes,
    ),
  );
}

EncryptedInboundEnvelope _inbound(String ciphertext) {
  return EncryptedInboundEnvelope(
    serverCursor: 1,
    envelopeId: '33333333-3333-4333-8333-333333333333',
    messageId: '44444444-4444-4444-8444-444444444444',
    circleId: '55555555-5555-4555-8555-555555555555',
    senderUserId: 1,
    senderDeviceId: '11111111-1111-4111-8111-111111111111',
    recipientDeviceId: '22222222-2222-4222-8222-222222222222',
    type: OrbitMessageType.text,
    ciphertext: ciphertext,
    createdAt: DateTime.utc(2026, 9, 6),
    expiresAt: DateTime.utc(2026, 10, 6),
  );
}
