enum SosStatus {
  active('active'),
  resolved('resolved');

  const SosStatus(this.apiValue);

  final String apiValue;

  static SosStatus parse(Object? value) {
    return switch (value) {
      'active' => SosStatus.active,
      'resolved' => SosStatus.resolved,
      _ => throw FormatException('Unsupported SOS status: $value'),
    };
  }
}

enum SosResponderStatus {
  pending('pending'),
  engaged('engaged'),
  declined('declined');

  const SosResponderStatus(this.apiValue);

  final String apiValue;

  static SosResponderStatus parse(Object? value) {
    return switch (value) {
      'pending' => SosResponderStatus.pending,
      'engaged' => SosResponderStatus.engaged,
      'declined' => SosResponderStatus.declined,
      _ => throw FormatException('Unsupported SOS responder status: $value'),
    };
  }
}

enum SosResolutionReason {
  safe('safe', 'I am safe'),
  falseAlarm('false_alarm', 'False alarm'),
  helpArrived('help_arrived', 'Help arrived'),
  other('other', 'Other');

  const SosResolutionReason(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class SosLocation {
  const SosLocation({
    required this.latitude,
    required this.longitude,
    this.accuracyMeters,
    this.recordedAt,
  });

  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime? recordedAt;

  factory SosLocation.fromJson(Map<String, Object?> json) {
    final latitude = _doubleValue(json['latitude']);
    final longitude = _doubleValue(json['longitude']);
    if (latitude == null || longitude == null) {
      throw const FormatException('Invalid SOS location.');
    }
    return SosLocation(
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: _doubleValue(json['accuracy_m']),
      recordedAt: _dateTimeValue(json['recorded_at']),
    );
  }
}

class SosResponder {
  const SosResponder({
    required this.userId,
    required this.status,
    this.engagedAt,
    this.respondedAt,
    this.location,
  });

  final int userId;
  final SosResponderStatus status;
  final DateTime? engagedAt;
  final DateTime? respondedAt;
  final SosLocation? location;

  factory SosResponder.fromJson(Map<String, Object?> json) {
    final userId = _intValue(json['user_id']);
    if (userId == null) {
      throw const FormatException('Invalid SOS responder.');
    }
    return SosResponder(
      userId: userId,
      status: SosResponderStatus.parse(json['status']),
      engagedAt: _dateTimeValue(json['engaged_at']),
      respondedAt: _dateTimeValue(json['responded_at']),
      location: _nullableLocation(json['location']),
    );
  }
}

class SosIncident {
  const SosIncident({
    required this.id,
    required this.circleId,
    required this.originatorUserId,
    required this.status,
    required this.escalationStage,
    required this.responders,
    this.activatedAt,
    this.resolvedAt,
    this.resolutionReason,
    this.recordingRef,
    this.recordingExpiresAt,
    this.originatorLocation,
  });

  final String id;
  final String circleId;
  final int originatorUserId;
  final SosStatus status;
  final int escalationStage;
  final DateTime? activatedAt;
  final DateTime? resolvedAt;
  final String? resolutionReason;
  final String? recordingRef;
  final DateTime? recordingExpiresAt;
  final SosLocation? originatorLocation;
  final List<SosResponder> responders;

  bool get isActive => status == SosStatus.active;

  SosResponder? responderFor(int userId) {
    for (final responder in responders) {
      if (responder.userId == userId) {
        return responder;
      }
    }
    return null;
  }

  factory SosIncident.fromJson(Map<String, Object?> json) {
    final id = _requiredString(json, 'id');
    final circleId = _requiredString(json, 'circle_id');
    final originatorUserId = _intValue(json['originator_user_id']);
    final escalationStage = _intValue(json['escalation_stage']);
    final rawResponders = json['responders'];
    if (originatorUserId == null ||
        escalationStage == null ||
        rawResponders is! List) {
      throw const FormatException('Invalid SOS incident response.');
    }

    return SosIncident(
      id: id,
      circleId: circleId,
      originatorUserId: originatorUserId,
      status: SosStatus.parse(json['status']),
      escalationStage: escalationStage,
      activatedAt: _dateTimeValue(json['activated_at']),
      resolvedAt: _dateTimeValue(json['resolved_at']),
      resolutionReason: _nullableString(json['resolution_reason']),
      recordingRef: _nullableString(json['recording_ref']),
      recordingExpiresAt: _dateTimeValue(json['recording_expires_at']),
      originatorLocation: _nullableLocation(json['originator_location']),
      responders: List<SosResponder>.unmodifiable(
        rawResponders.map((item) => SosResponder.fromJson(_requiredMap(item))),
      ),
    );
  }
}

class SosActivationInput {
  const SosActivationInput({
    required this.id,
    required this.circleId,
    this.latitude,
    this.longitude,
    this.locationAccuracyMeters,
    this.recordingRef,
  });

  final String id;
  final String circleId;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracyMeters;
  final String? recordingRef;

  Map<String, Object?> toApiPayload() {
    return <String, Object?>{
      'id': id,
      'circle_id': circleId,
      'recording_ref': ?recordingRef,
      'latitude': ?latitude,
      'longitude': ?longitude,
      'location_accuracy_m': ?locationAccuracyMeters,
    };
  }
}

Map<String, Object?> _requiredMap(Object? value) {
  if (value is! Map) {
    throw const FormatException('Expected a JSON object.');
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

SosLocation? _nullableLocation(Object? value) {
  if (value == null) {
    return null;
  }
  return SosLocation.fromJson(_requiredMap(value));
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = _nullableString(json[key]);
  if (value == null) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

String? _nullableString(Object? value) {
  return value is String && value.trim().isNotEmpty ? value.trim() : null;
}

int? _intValue(Object? value) {
  return switch (value) {
    int item => item,
    num item => item.toInt(),
    String item => int.tryParse(item),
    _ => null,
  };
}

double? _doubleValue(Object? value) {
  return switch (value) {
    num item => item.toDouble(),
    String item => double.tryParse(item),
    _ => null,
  };
}

DateTime? _dateTimeValue(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value)?.toLocal();
}
