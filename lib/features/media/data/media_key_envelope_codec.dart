import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../../messaging/domain/e2ee_identity.dart';
import '../../messaging/domain/messaging_models.dart';
import '../domain/media_models.dart';

class MediaKeyEnvelopeException implements Exception {
  const MediaKeyEnvelopeException(this.message);

  final String message;

  @override
  String toString() => 'MediaKeyEnvelopeException($message)';
}

class MediaKeyEnvelopeCodec {
  MediaKeyEnvelopeCodec({
    X25519? keyAgreement,
    Hkdf? keyDerivation,
    AesGcm? cipher,
  }) : _keyAgreement = keyAgreement ?? X25519(),
       _keyDerivation =
           keyDerivation ?? Hkdf(hmac: Hmac.sha256(), outputLength: 32),
       _cipher = cipher ?? AesGcm.with256bits();

  static const algorithm = 'orbit-media-key-x25519-aesgcm-v1';

  final X25519 _keyAgreement;
  final Hkdf _keyDerivation;
  final AesGcm _cipher;

  Future<OutboundMediaKeyEnvelope> wrap({
    required String assetId,
    required String circleId,
    required MessageDevice recipient,
    required List<int> mediaKeyBytes,
  }) async {
    if (mediaKeyBytes.length != 32) {
      throw const MediaKeyEnvelopeException('Invalid Orbit media key.');
    }
    if (recipient.identity.keyAgreementPublicKey.length != 32) {
      throw const MediaKeyEnvelopeException(
        'The recipient device encryption key is invalid.',
      );
    }
    final ephemeral = await _keyAgreement.newKeyPair();
    final ephemeralPublic = await ephemeral.extractPublicKey();
    final shared = await _keyAgreement.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(
        recipient.identity.keyAgreementPublicKey,
        type: KeyPairType.x25519,
      ),
    );
    final wrappingKey = await _derive(
      shared: shared,
      assetId: assetId,
      circleId: circleId,
      recipientDeviceId: recipient.deviceId,
    );
    final box = await _cipher.encrypt(mediaKeyBytes, secretKey: wrappingKey);
    final wire = jsonEncode(<String, Object>{
      'v': 1,
      'epk': base64Url.encode(ephemeralPublic.bytes),
      'nonce': base64Url.encode(box.nonce),
      'ct': base64Url.encode(box.cipherText),
      'mac': base64Url.encode(box.mac.bytes),
    });
    return OutboundMediaKeyEnvelope(
      recipientDeviceId: recipient.deviceId,
      algorithm: algorithm,
      encryptedKey: wire,
    );
  }

  Future<List<int>> unwrap({
    required OrbitMediaKeyEnvelope envelope,
    required String circleId,
    required DevicePrivateIdentity recipientIdentity,
  }) async {
    if (envelope.algorithm != algorithm) {
      throw const MediaKeyEnvelopeException(
        'Unsupported Orbit media key envelope.',
      );
    }
    final wire = _decode(envelope.encryptedKey);
    final ephemeral = _bytes(wire, 'epk', expectedLength: 32);
    final nonce = _bytes(wire, 'nonce', expectedLength: 12);
    final ciphertext = _bytes(wire, 'ct', expectedLength: 32);
    final mac = _bytes(wire, 'mac', expectedLength: 16);
    final shared = await _keyAgreement.sharedSecretKey(
      keyPair: recipientIdentity.keyAgreementKeyPair,
      remotePublicKey: SimplePublicKey(ephemeral, type: KeyPairType.x25519),
    );
    final wrappingKey = await _derive(
      shared: shared,
      assetId: envelope.assetId,
      circleId: circleId,
      recipientDeviceId: envelope.recipientDeviceId,
    );
    try {
      final clear = await _cipher.decrypt(
        SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
        secretKey: wrappingKey,
      );
      if (clear.length != 32) {
        throw const MediaKeyEnvelopeException(
          'The decrypted Orbit media key is invalid.',
        );
      }
      return clear;
    } on SecretBoxAuthenticationError {
      throw const MediaKeyEnvelopeException(
        'Orbit media key integrity verification failed.',
      );
    }
  }

  Future<SecretKeyData> _derive({
    required SecretKey shared,
    required String assetId,
    required String circleId,
    required String recipientDeviceId,
  }) {
    return _keyDerivation.deriveKey(
      secretKey: shared,
      nonce: utf8.encode(assetId),
      info: utf8.encode('orbit-media-key-v1|$circleId|$recipientDeviceId'),
    );
  }

  Map<String, Object?> _decode(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        throw const FormatException();
      }
      final map = decoded.map((key, item) => MapEntry(key.toString(), item));
      if (map['v'] != 1) {
        throw const FormatException();
      }
      return map;
    } on FormatException {
      throw const MediaKeyEnvelopeException(
        'Malformed Orbit media key envelope.',
      );
    }
  }

  List<int> _bytes(
    Map<String, Object?> map,
    String key, {
    int? expectedLength,
  }) {
    final value = map[key];
    if (value is! String || value.isEmpty) {
      throw const MediaKeyEnvelopeException(
        'Incomplete Orbit media key envelope.',
      );
    }
    try {
      final bytes = base64Url.decode(value);
      if (expectedLength != null && bytes.length != expectedLength) {
        throw const MediaKeyEnvelopeException(
          'Malformed Orbit media key envelope.',
        );
      }
      return bytes;
    } on FormatException {
      throw const MediaKeyEnvelopeException(
        'Malformed Orbit media key envelope.',
      );
    }
  }
}
