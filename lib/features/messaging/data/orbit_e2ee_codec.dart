import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import '../domain/e2ee_identity.dart';
import '../domain/messaging_models.dart';

class OrbitE2eeCodec {
  OrbitE2eeCodec({
    X25519? keyAgreement,
    Ed25519? signatures,
    AesGcm? cipher,
    Hkdf? keyDerivation,
    Sha256? hash,
  }) : this._(
         keyAgreement ?? X25519(),
         signatures ?? Ed25519(),
         cipher ?? AesGcm.with256bits(),
         keyDerivation ?? Hkdf(hmac: Hmac.sha256(), outputLength: 32),
         hash ?? Sha256(),
       );

  OrbitE2eeCodec._(
    this._keyAgreement,
    this._signatures,
    this._cipher,
    this._keyDerivation,
    this._hash,
  );

  final X25519 _keyAgreement;
  final Ed25519 _signatures;
  final AesGcm _cipher;
  final Hkdf _keyDerivation;
  final Sha256 _hash;

  Future<OutboundEnvelope> encryptText({
    required String envelopeId,
    required String messageId,
    required String circleId,
    required String senderDeviceId,
    required MessageDevice recipient,
    required DevicePrivateIdentity senderIdentity,
    required String plaintext,
  }) async {
    final ephemeral = await _keyAgreement.newKeyPair();
    final ephemeralPublic = await ephemeral.extractPublicKey();
    final shared = await _keyAgreement.sharedSecretKey(
      keyPair: ephemeral,
      remotePublicKey: SimplePublicKey(
        recipient.identity.keyAgreementPublicKey,
        type: KeyPairType.x25519,
      ),
    );
    final key = await _deriveEnvelopeKey(
      shared: shared,
      messageId: messageId,
      circleId: circleId,
      senderDeviceId: senderDeviceId,
      recipientDeviceId: recipient.deviceId,
    );
    final secretBox = await _cipher.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
    );

    final signedPayload = _signaturePayload(
      messageId: messageId,
      circleId: circleId,
      senderDeviceId: senderDeviceId,
      recipientDeviceId: recipient.deviceId,
      ephemeralPublicKey: ephemeralPublic.bytes,
      nonce: secretBox.nonce,
      ciphertext: secretBox.cipherText,
      mac: secretBox.mac.bytes,
    );
    final signature = await _signatures.sign(
      signedPayload,
      keyPair: senderIdentity.signingKeyPair,
    );

    final wire = jsonEncode(<String, Object>{
      'v': 1,
      'epk': base64Url.encode(ephemeralPublic.bytes),
      'nonce': base64Url.encode(secretBox.nonce),
      'ct': base64Url.encode(secretBox.cipherText),
      'mac': base64Url.encode(secretBox.mac.bytes),
      'sig': base64Url.encode(signature.bytes),
    });

    return OutboundEnvelope(
      envelopeId: envelopeId,
      recipientDeviceId: recipient.deviceId,
      ciphertext: wire,
    );
  }

  Future<DecryptedEnvelopePayload> decryptText({
    required EncryptedInboundEnvelope envelope,
    required DevicePrivateIdentity recipientIdentity,
    required DevicePublicIdentity senderIdentity,
  }) async {
    final wire = _decodeWire(envelope.ciphertext);
    final ephemeralPublicKey = _bytes(wire, 'epk');
    final nonce = _bytes(wire, 'nonce');
    final ciphertext = _bytes(wire, 'ct');
    final mac = _bytes(wire, 'mac');
    final signatureBytes = _bytes(wire, 'sig');

    final signedPayload = _signaturePayload(
      messageId: envelope.messageId,
      circleId: envelope.circleId,
      senderDeviceId: envelope.senderDeviceId,
      recipientDeviceId: envelope.recipientDeviceId,
      ephemeralPublicKey: ephemeralPublicKey,
      nonce: nonce,
      ciphertext: ciphertext,
      mac: mac,
    );
    final verified = await _signatures.verify(
      signedPayload,
      signature: Signature(
        signatureBytes,
        publicKey: SimplePublicKey(
          senderIdentity.signingPublicKey,
          type: KeyPairType.ed25519,
        ),
      ),
    );
    if (!verified) {
      throw const OrbitE2eeException(
        'Message authenticity verification failed.',
      );
    }

    final shared = await _keyAgreement.sharedSecretKey(
      keyPair: recipientIdentity.keyAgreementKeyPair,
      remotePublicKey: SimplePublicKey(
        ephemeralPublicKey,
        type: KeyPairType.x25519,
      ),
    );
    final key = await _deriveEnvelopeKey(
      shared: shared,
      messageId: envelope.messageId,
      circleId: envelope.circleId,
      senderDeviceId: envelope.senderDeviceId,
      recipientDeviceId: envelope.recipientDeviceId,
    );

    try {
      final clear = await _cipher.decrypt(
        SecretBox(ciphertext, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
      );
      return DecryptedEnvelopePayload(body: utf8.decode(clear));
    } on SecretBoxAuthenticationError {
      throw const OrbitE2eeException('Message integrity verification failed.');
    } on FormatException {
      throw const OrbitE2eeException('Message text could not be decoded.');
    }
  }

  Future<String> fingerprint(DevicePublicIdentity identity) async {
    final hash = await _hash.hash(utf8.encode(identity.toServerValue()));
    return hash.bytes
        .take(12)
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join(':');
  }

  Future<SecretKeyData> _deriveEnvelopeKey({
    required SecretKey shared,
    required String messageId,
    required String circleId,
    required String senderDeviceId,
    required String recipientDeviceId,
  }) {
    return _keyDerivation.deriveKey(
      secretKey: shared,
      nonce: utf8.encode(messageId),
      info: utf8.encode(
        'orbit-e2ee-v1|$circleId|$senderDeviceId|$recipientDeviceId',
      ),
    );
  }

  List<int> _signaturePayload({
    required String messageId,
    required String circleId,
    required String senderDeviceId,
    required String recipientDeviceId,
    required List<int> ephemeralPublicKey,
    required List<int> nonce,
    required List<int> ciphertext,
    required List<int> mac,
  }) {
    return utf8.encode(
      <String>[
        'orbit-e2ee-v1',
        messageId,
        circleId,
        senderDeviceId,
        recipientDeviceId,
        base64Url.encode(ephemeralPublicKey),
        base64Url.encode(nonce),
        base64Url.encode(ciphertext),
        base64Url.encode(mac),
      ].join('|'),
    );
  }

  Map<String, Object?> _decodeWire(String ciphertext) {
    try {
      final decoded = jsonDecode(ciphertext);
      if (decoded is! Map) {
        throw const FormatException();
      }
      final map = decoded.map((key, item) => MapEntry(key.toString(), item));
      if (map['v'] != 1) {
        throw const FormatException();
      }
      return map;
    } on FormatException {
      throw const OrbitE2eeException('Unsupported encrypted message envelope.');
    }
  }

  List<int> _bytes(Map<String, Object?> map, String key) {
    final value = map[key];
    if (value is! String || value.isEmpty) {
      throw const OrbitE2eeException(
        'Encrypted message envelope is incomplete.',
      );
    }
    try {
      return base64Url.decode(value);
    } on FormatException {
      throw const OrbitE2eeException(
        'Encrypted message envelope is malformed.',
      );
    }
  }
}
