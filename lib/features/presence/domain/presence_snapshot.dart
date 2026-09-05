enum PresenceStatus {
  online,
  idle,
  offline,
  ghost;

  static PresenceStatus parse(Object? value) {
    return switch (value) {
      'online' => PresenceStatus.online,
      'idle' => PresenceStatus.idle,
      'ghost' => PresenceStatus.ghost,
      _ => PresenceStatus.offline,
    };
  }
}

enum PresenceLocationMode {
  precise,
  approximate,
  hidden,
  ghost;

  static PresenceLocationMode parse(Object? value) {
    return switch (value) {
      'precise' => PresenceLocationMode.precise,
      'approximate' => PresenceLocationMode.approximate,
      'ghost' => PresenceLocationMode.ghost,
      _ => PresenceLocationMode.hidden,
    };
  }

  String get apiValue => name;
}

class PresenceSnapshot {
  const PresenceSnapshot({
    required this.status,
    required this.locationMode,
    required this.globalGhostMode,
    this.latitude,
    this.longitude,
    this.accuracyMeters,
    this.locationUpdatedAt,
    this.batteryLevel,
    this.isCharging,
    this.networkType,
    this.movementType,
    this.lastSeenAt,
    this.deviceId,
  });

  factory PresenceSnapshot.fromJson(Map<String, Object?> json) {
    final location = _stringMap(json['location']);
    final battery = _stringMap(json['battery']);

    return PresenceSnapshot(
      status: PresenceStatus.parse(json['status']),
      locationMode: PresenceLocationMode.parse(location['mode']),
      globalGhostMode: json['global_ghost_mode'] == true,
      latitude: _doubleOrNull(location['latitude']),
      longitude: _doubleOrNull(location['longitude']),
      accuracyMeters: _doubleOrNull(location['accuracy_meters']),
      locationUpdatedAt: _dateOrNull(location['updated_at']),
      batteryLevel: _intOrNull(battery['level']),
      isCharging: battery['is_charging'] is bool
          ? battery['is_charging'] as bool
          : null,
      networkType: _nullableString(json['network_type']),
      movementType: _nullableString(json['movement_type']),
      lastSeenAt: _dateOrNull(json['last_seen_at']),
      deviceId: _nullableString(json['device_id']),
    );
  }

  final PresenceStatus status;
  final PresenceLocationMode locationMode;
  final bool globalGhostMode;
  final double? latitude;
  final double? longitude;
  final double? accuracyMeters;
  final DateTime? locationUpdatedAt;
  final int? batteryLevel;
  final bool? isCharging;
  final String? networkType;
  final String? movementType;
  final DateTime? lastSeenAt;
  final String? deviceId;

  bool get hasCoordinates => latitude != null && longitude != null;

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      return const <String, Object?>{};
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String? _nullableString(Object? value) {
    return value is String && value.isNotEmpty ? value : null;
  }

  static double? _doubleOrNull(Object? value) {
    return switch (value) {
      num number => number.toDouble(),
      String text => double.tryParse(text),
      _ => null,
    };
  }

  static int? _intOrNull(Object? value) {
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String text => int.tryParse(text),
      _ => null,
    };
  }

  static DateTime? _dateOrNull(Object? value) {
    return value is String && value.isNotEmpty
        ? DateTime.tryParse(value)
        : null;
  }
}

class CirclePrivacySetting {
  const CirclePrivacySetting({
    required this.circleId,
    required this.circleName,
    required this.membershipId,
    required this.locationMode,
    required this.canPing,
  });

  final String circleId;
  final String circleName;
  final String membershipId;
  final PresenceLocationMode locationMode;
  final bool canPing;
}
