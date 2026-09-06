import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/features/media/data/media_key_envelope_codec.dart';
import 'package:orbit_app/features/media/domain/media_models.dart';
import 'package:orbit_app/features/messaging/domain/e2ee_identity.dart';
import 'package:orbit_app/features/messaging/domain/messaging_models.dart';

void main() {
  test('wraps one media key for one recipient device and unwraps it', () async {
    final identity = await _identity();
    final recipient = MessageDevice(
      deviceId: 'device-1',
      userId: 7,
      displayName: 'Avery',
      platform: 'android',
      identity: identity.publicIdentity,
    );
    final mediaKey = List<int>.generate(32, (index) => index + 1);
    final codec = MediaKeyEnvelopeCodec();

    final outbound = await codec.wrap(
      assetId: 'asset-id',
      circleId: 'circle-id',
      recipient: recipient,
      mediaKeyBytes: mediaKey,
    );

    expect(outbound.algorithm, MediaKeyEnvelopeCodec.algorithm);
    expect(outbound.encryptedKey, isNot(contains(mediaKey.join(','))));

    final clear = await codec.unwrap(
      envelope: OrbitMediaKeyEnvelope(
        assetId: 'asset-id',
        recipientDeviceId: 'device-1',
        algorithm: outbound.algorithm,
        encryptedKey: outbound.encryptedKey,
      ),
      circleId: 'circle-id',
      recipientIdentity: identity,
    );

    expect(clear, mediaKey);
  });

  test('rejects malformed envelope field lengths before decryption', () async {
    final identity = await _identity();
    final malformed = jsonEncode(<String, Object>{
      'v': 1,
      'epk': base64Url.encode(const <int>[1, 2, 3]),
      'nonce': base64Url.encode(List<int>.filled(12, 0)),
      'ct': base64Url.encode(List<int>.filled(32, 0)),
      'mac': base64Url.encode(List<int>.filled(16, 0)),
    });

    await expectLater(
      MediaKeyEnvelopeCodec().unwrap(
        envelope: OrbitMediaKeyEnvelope(
          assetId: 'asset-id',
          recipientDeviceId: 'device-1',
          algorithm: MediaKeyEnvelopeCodec.algorithm,
          encryptedKey: malformed,
        ),
        circleId: 'circle-id',
        recipientIdentity: identity,
      ),
      throwsA(isA<MediaKeyEnvelopeException>()),
    );
  });
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
