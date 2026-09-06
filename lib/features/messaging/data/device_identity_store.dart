import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/e2ee_identity.dart';
import '../domain/messaging_models.dart';

abstract interface class DeviceIdentityStore {
  Future<DevicePrivateIdentity> getOrCreate(String serverDeviceId);
}

class SecureDeviceIdentityStore implements DeviceIdentityStore {
  SecureDeviceIdentityStore(this._storage);

  static const _namespace = 'orbit.messaging.identity.v1';

  final FlutterSecureStorage _storage;
  final X25519 _x25519 = X25519();
  final Ed25519 _ed25519 = Ed25519();

  @override
  Future<DevicePrivateIdentity> getOrCreate(String serverDeviceId) async {
    final storageKey = '$_namespace.$serverDeviceId';
    final existing = await _storage.read(key: storageKey);
    if (existing != null && existing.isNotEmpty) {
      try {
        return _decode(existing);
      } on FormatException {
        await _storage.delete(key: storageKey);
      } on TypeError {
        await _storage.delete(key: storageKey);
      }
    }

    final agreement = await (await _x25519.newKeyPair()).extract();
    final signing = await (await _ed25519.newKeyPair()).extract();
    final identity = DevicePrivateIdentity(
      keyAgreementKeyPair: agreement,
      signingKeyPair: signing,
      publicIdentity: DevicePublicIdentity(
        keyAgreementPublicKey: agreement.publicKey.bytes,
        signingPublicKey: signing.publicKey.bytes,
      ),
    );

    await _storage.write(
      key: storageKey,
      value: jsonEncode(<String, Object>{
        'v': 1,
        'kx_private': base64Url.encode(agreement.bytes),
        'kx_public': base64Url.encode(agreement.publicKey.bytes),
        'sig_private': base64Url.encode(signing.bytes),
        'sig_public': base64Url.encode(signing.publicKey.bytes),
      }),
    );
    return identity;
  }

  DevicePrivateIdentity _decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Invalid stored Orbit messaging identity.');
    }
    final map = decoded.map((key, item) => MapEntry(key.toString(), item));
    if (map['v'] != 1) {
      throw const FormatException('Unsupported Orbit messaging identity.');
    }

    final kxPrivate = _decodeBytes(map['kx_private']);
    final kxPublic = _decodeBytes(map['kx_public']);
    final sigPrivate = _decodeBytes(map['sig_private']);
    final sigPublic = _decodeBytes(map['sig_public']);

    final agreement = SimpleKeyPairData(
      kxPrivate,
      publicKey: SimplePublicKey(kxPublic, type: KeyPairType.x25519),
      type: KeyPairType.x25519,
    );
    final signing = SimpleKeyPairData(
      sigPrivate,
      publicKey: SimplePublicKey(sigPublic, type: KeyPairType.ed25519),
      type: KeyPairType.ed25519,
    );

    return DevicePrivateIdentity(
      keyAgreementKeyPair: agreement,
      signingKeyPair: signing,
      publicIdentity: DevicePublicIdentity(
        keyAgreementPublicKey: kxPublic,
        signingPublicKey: sigPublic,
      ),
    );
  }

  List<int> _decodeBytes(Object? value) {
    if (value is! String || value.isEmpty) {
      throw const FormatException('Invalid stored Orbit messaging key bytes.');
    }
    return base64Url.decode(value);
  }
}
