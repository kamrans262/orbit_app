import 'package:cryptography/cryptography.dart';

import 'messaging_models.dart';

class DevicePrivateIdentity {
  const DevicePrivateIdentity({
    required this.keyAgreementKeyPair,
    required this.signingKeyPair,
    required this.publicIdentity,
  });

  final SimpleKeyPairData keyAgreementKeyPair;
  final SimpleKeyPairData signingKeyPair;
  final DevicePublicIdentity publicIdentity;
}

class DecryptedEnvelopePayload {
  const DecryptedEnvelopePayload({required this.body});

  final String body;
}

class OrbitE2eeException implements Exception {
  const OrbitE2eeException(this.message);

  final String message;

  @override
  String toString() => 'OrbitE2eeException($message)';
}
