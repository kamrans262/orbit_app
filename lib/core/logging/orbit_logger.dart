import 'package:flutter/foundation.dart';

class OrbitLogger {
  const OrbitLogger();

  static const _sensitiveFragments = <String>{
    'authorization',
    'token',
    'otp',
    'ciphertext',
    'private_key',
    'refresh',
    'recording',
    'location',
    'email',
  };

  void debug(String message, {Map<String, Object?> fields = const {}}) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[Orbit] $message ${_safeFields(fields)}');
  }

  void error(String message, {Map<String, Object?> fields = const {}}) {
    if (!kDebugMode) {
      return;
    }
    debugPrint('[Orbit][error] $message ${_safeFields(fields)}');
  }

  Map<String, Object?> _safeFields(Map<String, Object?> fields) {
    return fields.map((key, value) {
      final normalized = key.toLowerCase();
      final sensitive = _sensitiveFragments.any(normalized.contains);
      return MapEntry(key, sensitive ? '<redacted>' : value);
    });
  }
}
