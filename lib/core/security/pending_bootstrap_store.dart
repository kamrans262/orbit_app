import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/auth/domain/auth_results.dart';

abstract interface class PendingBootstrapStore {
  Future<PendingDeviceBootstrap?> read();
  Future<void> write(PendingDeviceBootstrap pending);
  Future<void> clear();
}

class SecurePendingBootstrapStore implements PendingBootstrapStore {
  SecurePendingBootstrapStore(this._storage);

  static const _key = 'orbit.auth.pending_device_bootstrap.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<PendingDeviceBootstrap?> read() async {
    final raw = await _storage.read(key: _key);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await clear();
        return null;
      }
      return PendingDeviceBootstrap.fromJson(decoded.cast<String, Object?>());
    } on FormatException {
      await clear();
      return null;
    } on TypeError {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(PendingDeviceBootstrap pending) {
    return _storage.write(key: _key, value: jsonEncode(pending.toJson()));
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);
}
