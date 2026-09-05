import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

abstract interface class ClientDeviceIdStore {
  Future<String> getOrCreate();
}

class SecureClientDeviceIdStore implements ClientDeviceIdStore {
  SecureClientDeviceIdStore(
    FlutterSecureStorage storage, {
    Uuid uuid = const Uuid(),
  }) : this._(storage, uuid);

  SecureClientDeviceIdStore._(this._storage, this._uuid);

  static const _key = 'orbit.client_device_id.v1';

  final FlutterSecureStorage _storage;
  final Uuid _uuid;

  @override
  Future<String> getOrCreate() async {
    final existing = await _storage.read(key: _key);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }

    final generated = _uuid.v4();
    await _storage.write(key: _key, value: generated);
    return generated;
  }
}
