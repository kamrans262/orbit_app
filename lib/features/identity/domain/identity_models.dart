class OrbitIdentityDevice {
  const OrbitIdentityDevice({
    required this.id,
    this.clientDeviceId,
    this.deviceName,
    this.platform,
    this.lastSeenAt,
    required this.trustStatus,
  });

  factory OrbitIdentityDevice.fromJson(Map<String, Object?> json) {
    final id = _requiredString(json, 'id');
    return OrbitIdentityDevice(
      id: id,
      clientDeviceId: _nullableString(json['client_device_id']),
      deviceName: _nullableString(json['device_name']),
      platform: _nullableString(json['platform']),
      lastSeenAt: _dateValue(json['last_seen_at']),
      trustStatus: _nullableString(json['trust_status']) ?? 'legacy_unverified',
    );
  }

  final String id;
  final String? clientDeviceId;
  final String? deviceName;
  final String? platform;
  final DateTime? lastSeenAt;
  final String trustStatus;

  String get displayName => deviceName ?? platform ?? 'Orbit device';
}

class OrbitIdentitySessionSummary {
  const OrbitIdentitySessionSummary({
    required this.id,
    required this.deviceId,
    this.deviceName,
    this.platform,
    required this.status,
    this.lastSeenAt,
    this.accessExpiresAt,
    this.refreshExpiresAt,
    this.revokedAt,
    this.createdAt,
  });

  factory OrbitIdentitySessionSummary.fromJson(Map<String, Object?> json) {
    return OrbitIdentitySessionSummary(
      id: _requiredString(json, 'id'),
      deviceId: _requiredString(json, 'device_id'),
      deviceName: _nullableString(json['device_name']),
      platform: _nullableString(json['platform']),
      status: _nullableString(json['status']) ?? 'unknown',
      lastSeenAt: _dateValue(json['last_seen_at']),
      accessExpiresAt: _dateValue(json['access_expires_at']),
      refreshExpiresAt: _dateValue(json['refresh_expires_at']),
      revokedAt: _dateValue(json['revoked_at']),
      createdAt: _dateValue(json['created_at']),
    );
  }

  final String id;
  final String deviceId;
  final String? deviceName;
  final String? platform;
  final String status;
  final DateTime? lastSeenAt;
  final DateTime? accessExpiresAt;
  final DateTime? refreshExpiresAt;
  final DateTime? revokedAt;
  final DateTime? createdAt;

  bool get isActive => status == 'active' && revokedAt == null;
  String get displayName => deviceName ?? platform ?? 'Orbit session';
}

class SecurityAuditEntry {
  const SecurityAuditEntry({
    required this.id,
    required this.action,
    this.targetType,
    this.targetId,
    this.occurredAt,
  });

  factory SecurityAuditEntry.fromJson(Map<String, Object?> json) {
    return SecurityAuditEntry(
      id: _requiredString(json, 'id'),
      action: _requiredString(json, 'action'),
      targetType: _nullableString(json['target_type']),
      targetId: _nullableString(json['target_id']),
      occurredAt: _dateValue(json['occurred_at']),
    );
  }

  final String id;
  final String action;
  final String? targetType;
  final String? targetId;
  final DateTime? occurredAt;
}

class PrivacyNotificationSummary {
  const PrivacyNotificationSummary({
    required this.pushEnabled,
    required this.inAppEnabled,
    required this.quietHoursEnabled,
  });

  factory PrivacyNotificationSummary.fromJson(Map<String, Object?> json) {
    return PrivacyNotificationSummary(
      pushEnabled: json['push_enabled'] != false,
      inAppEnabled: json['in_app_enabled'] != false,
      quietHoursEnabled: json['quiet_hours_enabled'] == true,
    );
  }

  final bool pushEnabled;
  final bool inAppEnabled;
  final bool quietHoursEnabled;
}

class DataExportRequestSummary {
  const DataExportRequestSummary({
    required this.id,
    required this.status,
    this.requestedAt,
    this.completedAt,
    this.expiresAt,
    this.hasPayload = false,
  });

  factory DataExportRequestSummary.fromJson(Map<String, Object?> json) {
    return DataExportRequestSummary(
      id: _requiredString(json, 'id'),
      status: _nullableString(json['status']) ?? 'unknown',
      requestedAt: _dateValue(json['requested_at']),
      completedAt: _dateValue(json['completed_at']),
      expiresAt: _dateValue(json['expires_at']),
      hasPayload: json['payload'] is Map,
    );
  }

  final String id;
  final String status;
  final DateTime? requestedAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final bool hasPayload;
}

class AccountDeletionRequestSummary {
  const AccountDeletionRequestSummary({
    this.id,
    required this.status,
    this.requestedAt,
    this.scheduledFor,
    this.blockingReason,
    this.cancelledAt,
    this.completedAt,
  });

  factory AccountDeletionRequestSummary.fromJson(Map<String, Object?> json) {
    return AccountDeletionRequestSummary(
      id: _nullableString(json['id']),
      status: _nullableString(json['status']) ?? 'unknown',
      requestedAt: _dateValue(json['requested_at']),
      scheduledFor: _dateValue(json['scheduled_for']),
      blockingReason: _nullableString(json['blocking_reason']),
      cancelledAt: _dateValue(json['cancelled_at']),
      completedAt: _dateValue(json['completed_at']),
    );
  }

  final String? id;
  final String status;
  final DateTime? requestedAt;
  final DateTime? scheduledFor;
  final String? blockingReason;
  final DateTime? cancelledAt;
  final DateTime? completedAt;

  bool get canCancel => status == 'pending' || status == 'blocked';
}

class PrivacySummary {
  const PrivacySummary({
    required this.globalGhostMode,
    this.readReceiptsEnabled,
    this.notificationPreferences,
    required this.circleCount,
    this.accountDeletion,
    this.dataExport,
  });

  factory PrivacySummary.fromJson(Map<String, Object?> json) {
    final notifications = _mapValue(json['notification_preferences']);
    final deletion = _mapValue(json['account_deletion']);
    final export = _mapValue(json['data_export']);
    final circles = json['circles'];

    return PrivacySummary(
      globalGhostMode: json['global_ghost_mode'] == true,
      readReceiptsEnabled: _boolValue(json['read_receipts_enabled']),
      notificationPreferences: notifications == null
          ? null
          : PrivacyNotificationSummary.fromJson(notifications),
      circleCount: circles is List ? circles.length : 0,
      accountDeletion: deletion == null
          ? null
          : AccountDeletionRequestSummary.fromJson(deletion),
      dataExport: export == null
          ? null
          : DataExportRequestSummary.fromJson(export),
    );
  }

  final bool globalGhostMode;
  final bool? readReceiptsEnabled;
  final PrivacyNotificationSummary? notificationPreferences;
  final int circleCount;
  final AccountDeletionRequestSummary? accountDeletion;
  final DataExportRequestSummary? dataExport;
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is String && value.isNotEmpty) {
    return value;
  }
  if (value is num) {
    return value.toString();
  }
  throw FormatException('Missing or invalid $key.');
}

String? _nullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  if (value is num) {
    return value.toString();
  }
  return null;
}

DateTime? _dateValue(Object? value) {
  return value is String && value.isNotEmpty ? DateTime.tryParse(value) : null;
}

Map<String, Object?>? _mapValue(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

bool? _boolValue(Object? value) {
  return value is bool ? value : null;
}
