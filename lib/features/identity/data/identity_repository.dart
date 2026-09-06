import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../domain/identity_models.dart';

abstract interface class IdentityRepository {
  Future<PrivacySummary> privacySummary();
  Future<List<OrbitIdentityDevice>> listDevices();
  Future<void> renameDevice(String deviceId, String deviceName);
  Future<List<OrbitIdentitySessionSummary>> listSessions();
  Future<void> revokeSession(String sessionId);
  Future<int> revokeOtherSessions();
  Future<List<SecurityAuditEntry>> listAuditLogs({int limit = 50});
  Future<DataExportRequestSummary> requestDataExport();
  Future<DataExportRequestSummary> getDataExport(String exportId);
  Future<AccountDeletionRequestSummary?> getAccountDeletion();
  Future<AccountDeletionRequestSummary> requestAccountDeletion({
    String? reason,
  });
  Future<bool> cancelAccountDeletion();
}

class HttpIdentityRepository implements IdentityRepository {
  const HttpIdentityRepository({required OrbitApiClient apiClient})
    : _api = apiClient;

  final OrbitApiClient _api;

  @override
  Future<PrivacySummary> privacySummary() async {
    final data = await _api.getDataMap('v1/identity/privacy');
    try {
      return PrivacySummary.fromJson(data.cast<String, Object?>());
    } on FormatException {
      throw _invalid('privacy');
    }
  }

  @override
  Future<List<OrbitIdentityDevice>> listDevices() async {
    final data = await _api.getDataList('v1/me/devices');
    return _parseList(data, OrbitIdentityDevice.fromJson, 'device');
  }

  @override
  Future<void> renameDevice(String deviceId, String deviceName) async {
    final clean = deviceName.trim();
    if (clean.isEmpty || clean.length > 100) {
      throw const OrbitApiException(
        code: 'DEVICE_NAME_INVALID',
        message: 'Device name must contain between 1 and 100 characters.',
      );
    }
    await _api.putDataMap(
      'v1/me/devices/${Uri.encodeComponent(deviceId)}/name',
      data: <String, Object?>{'device_name': clean},
      allowAuthRetry: true,
    );
  }

  @override
  Future<List<OrbitIdentitySessionSummary>> listSessions() async {
    final data = await _api.getDataList('v1/identity/sessions');
    return _parseList(data, OrbitIdentitySessionSummary.fromJson, 'session');
  }

  @override
  Future<void> revokeSession(String sessionId) {
    return _api.delete(
      'v1/identity/sessions/${Uri.encodeComponent(sessionId)}',
      allowAuthRetry: true,
    );
  }

  @override
  Future<int> revokeOtherSessions() async {
    final data = await _api.postDataMap(
      'v1/identity/sessions/revoke-others',
      allowAuthRetry: true,
    );
    final value = data['revoked'];
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    throw _invalid('session revocation');
  }

  @override
  Future<List<SecurityAuditEntry>> listAuditLogs({int limit = 50}) async {
    final data = await _api.getDataList(
      'v1/identity/audit-logs',
      queryParameters: <String, Object?>{'limit': limit.clamp(1, 100)},
    );
    return _parseList(data, SecurityAuditEntry.fromJson, 'security activity');
  }

  @override
  Future<DataExportRequestSummary> requestDataExport() async {
    final data = await _api.postDataMap(
      'v1/identity/data-exports',
      allowAuthRetry: true,
    );
    return _parseExport(data);
  }

  @override
  Future<DataExportRequestSummary> getDataExport(String exportId) async {
    final data = await _api.getDataMap(
      'v1/identity/data-exports/${Uri.encodeComponent(exportId)}',
    );
    return _parseExport(data);
  }

  @override
  Future<AccountDeletionRequestSummary?> getAccountDeletion() async {
    final data = await _api.getDataMap('v1/identity/account-deletion');
    if (data.isEmpty) {
      return null;
    }
    return _parseDeletion(data);
  }

  @override
  Future<AccountDeletionRequestSummary> requestAccountDeletion({
    String? reason,
  }) async {
    final clean = reason?.trim();
    final data = await _api.postDataMap(
      'v1/identity/account-deletion',
      data: <String, Object?>{
        if (clean != null && clean.isNotEmpty) 'reason': clean,
      },
      allowAuthRetry: true,
    );
    return _parseDeletion(data);
  }

  @override
  Future<bool> cancelAccountDeletion() async {
    await _api.delete('v1/identity/account-deletion', allowAuthRetry: true);
    return true;
  }

  static DataExportRequestSummary _parseExport(Map<String, dynamic> data) {
    try {
      return DataExportRequestSummary.fromJson(data.cast<String, Object?>());
    } on FormatException {
      throw _invalid('data export');
    }
  }

  static AccountDeletionRequestSummary _parseDeletion(
    Map<String, dynamic> data,
  ) {
    try {
      return AccountDeletionRequestSummary.fromJson(
        data.cast<String, Object?>(),
      );
    } on FormatException {
      throw _invalid('account deletion');
    }
  }

  static List<T> _parseList<T>(
    List<dynamic> data,
    T Function(Map<String, Object?>) parser,
    String label,
  ) {
    try {
      return List<T>.unmodifiable(data.map((item) => parser(_stringMap(item))));
    } on FormatException {
      throw _invalid(label);
    }
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected JSON object.');
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static OrbitApiException _invalid(String label) {
    return OrbitApiException(
      code: 'INVALID_RESPONSE',
      message: 'Orbit returned unexpected $label information.',
    );
  }
}
