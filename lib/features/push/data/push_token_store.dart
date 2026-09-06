import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/providers/core_providers.dart';

abstract interface class PushTokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecurePushTokenStore implements PushTokenStore {
  SecurePushTokenStore(this._storage);

  static const _key = 'orbit.push.token.v1';
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() async {
    final value = await _storage.read(key: _key);
    return value == null || value.isEmpty ? null : value;
  }

  @override
  Future<void> write(String token) => _storage.write(key: _key, value: token);

  @override
  Future<void> clear() => _storage.delete(key: _key);
}

final pushTokenStoreProvider = Provider<PushTokenStore>((ref) {
  return SecurePushTokenStore(ref.watch(flutterSecureStorageProvider));
});
