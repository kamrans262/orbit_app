import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SosLocalIncident {
  const SosLocalIncident({
    required this.sosId,
    required this.circleId,
    required this.userId,
    required this.isOriginator,
  });

  final String sosId;
  final String circleId;
  final int userId;
  final bool isOriginator;

  Map<String, Object?> toJson() => <String, Object?>{
    'sos_id': sosId,
    'circle_id': circleId,
    'user_id': userId,
    'is_originator': isOriginator,
  };

  factory SosLocalIncident.fromJson(Map<String, Object?> json) {
    final sosId = json['sos_id'];
    final circleId = json['circle_id'];
    final userId = json['user_id'];
    final isOriginator = json['is_originator'];
    if (sosId is! String ||
        sosId.isEmpty ||
        circleId is! String ||
        circleId.isEmpty ||
        userId is! int ||
        isOriginator is! bool) {
      throw const FormatException('Invalid local SOS state.');
    }
    return SosLocalIncident(
      sosId: sosId,
      circleId: circleId,
      userId: userId,
      isOriginator: isOriginator,
    );
  }
}

class SosPendingActivation {
  const SosPendingActivation({
    required this.sosId,
    required this.circleId,
    required this.userId,
  });

  final String sosId;
  final String circleId;
  final int userId;

  Map<String, Object?> toJson() => <String, Object?>{
    'sos_id': sosId,
    'circle_id': circleId,
    'user_id': userId,
  };

  factory SosPendingActivation.fromJson(Map<String, Object?> json) {
    final sosId = json['sos_id'];
    final circleId = json['circle_id'];
    final userId = json['user_id'];
    if (sosId is! String ||
        sosId.isEmpty ||
        circleId is! String ||
        circleId.isEmpty ||
        userId is! int) {
      throw const FormatException('Invalid pending SOS activation state.');
    }
    return SosPendingActivation(
      sosId: sosId,
      circleId: circleId,
      userId: userId,
    );
  }
}

abstract interface class SosLocalStateStore {
  Future<SosLocalIncident?> read();
  Future<void> write(SosLocalIncident incident);
  Future<void> clear();
  Future<SosPendingActivation?> readPendingActivation();
  Future<void> writePendingActivation(SosPendingActivation activation);
  Future<void> clearPendingActivation();
}

class SecureSosLocalStateStore implements SosLocalStateStore {
  const SecureSosLocalStateStore(this._storage);

  static const String _key = 'orbit.sos.active.v1';
  static const String _pendingKey = 'orbit.sos.pending_activation.v1';

  final FlutterSecureStorage _storage;

  @override
  Future<SosLocalIncident?> read() async {
    final encoded = await _storage.read(key: _key);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        throw const FormatException('Invalid local SOS state.');
      }
      return SosLocalIncident.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on Object {
      await clear();
      return null;
    }
  }

  @override
  Future<void> write(SosLocalIncident incident) {
    return _storage.write(key: _key, value: jsonEncode(incident.toJson()));
  }

  @override
  Future<void> clear() => _storage.delete(key: _key);

  @override
  Future<SosPendingActivation?> readPendingActivation() async {
    final encoded = await _storage.read(key: _pendingKey);
    if (encoded == null || encoded.isEmpty) {
      return null;
    }
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map) {
        throw const FormatException('Invalid pending SOS activation state.');
      }
      return SosPendingActivation.fromJson(
        decoded.map((key, value) => MapEntry(key.toString(), value)),
      );
    } on Object {
      await clearPendingActivation();
      return null;
    }
  }

  @override
  Future<void> writePendingActivation(SosPendingActivation activation) {
    return _storage.write(
      key: _pendingKey,
      value: jsonEncode(activation.toJson()),
    );
  }

  @override
  Future<void> clearPendingActivation() => _storage.delete(key: _pendingKey);
}
