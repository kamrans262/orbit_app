class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.accessExpiresAt,
    required this.refreshToken,
    required this.refreshExpiresAt,
    required this.sessionId,
    required this.deviceId,
  });

  factory AuthSession.fromJson(Map<String, Object?> json) {
    return AuthSession(
      accessToken: _requiredString(json, 'access_token'),
      accessExpiresAt: DateTime.parse(
        _requiredString(json, 'access_expires_at'),
      ),
      refreshToken: _requiredString(json, 'refresh_token'),
      refreshExpiresAt: DateTime.parse(
        _requiredString(json, 'refresh_expires_at'),
      ),
      sessionId: _requiredString(json, 'session_id'),
      deviceId: _requiredString(json, 'device_id'),
    );
  }

  factory AuthSession.fromIdentityPair(
    Map<String, Object?> data, {
    required String deviceId,
  }) {
    return AuthSession(
      accessToken: _requiredString(data, 'access_token'),
      accessExpiresAt: DateTime.parse(
        _requiredString(data, 'access_expires_at'),
      ),
      refreshToken: _requiredString(data, 'refresh_token'),
      refreshExpiresAt: DateTime.parse(
        _requiredString(data, 'refresh_expires_at'),
      ),
      sessionId: _requiredString(data, 'session_id'),
      deviceId: deviceId,
    );
  }

  final String accessToken;
  final DateTime accessExpiresAt;
  final String refreshToken;
  final DateTime refreshExpiresAt;
  final String sessionId;
  final String deviceId;

  bool shouldRefresh({
    DateTime? now,
    Duration skew = const Duration(minutes: 1),
  }) {
    final current = (now ?? DateTime.now()).toUtc();
    return accessExpiresAt.toUtc().isBefore(current.add(skew));
  }

  bool refreshExpired({DateTime? now}) {
    return refreshExpiresAt.toUtc().isBefore((now ?? DateTime.now()).toUtc());
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'access_token': accessToken,
    'access_expires_at': accessExpiresAt.toUtc().toIso8601String(),
    'refresh_token': refreshToken,
    'refresh_expires_at': refreshExpiresAt.toUtc().toIso8601String(),
    'session_id': sessionId,
    'device_id': deviceId,
  };

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Missing or invalid $key.');
    }
    return value;
  }
}
