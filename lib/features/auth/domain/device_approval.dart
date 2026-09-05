class DeviceApproval {
  const DeviceApproval({
    required this.id,
    required this.deviceId,
    required this.status,
    this.requestedAt,
    this.expiresAt,
    this.decidedAt,
  });

  factory DeviceApproval.fromJson(Map<String, Object?> json) {
    return DeviceApproval(
      id: _requiredString(json, 'id'),
      deviceId: _requiredString(json, 'device_id'),
      status: _requiredString(json, 'status'),
      requestedAt: _date(json['requested_at']),
      expiresAt: _date(json['expires_at']),
      decidedAt: _date(json['decided_at']),
    );
  }

  final String id;
  final String deviceId;
  final String status;
  final DateTime? requestedAt;
  final DateTime? expiresAt;
  final DateTime? decidedAt;

  bool get isPending => status == 'pending';

  static String _requiredString(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('Invalid device approval $key.');
    }
    return value;
  }

  static DateTime? _date(Object? value) {
    if (value is! String || value.isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
