class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.type,
    required this.circleId,
    required this.sourceType,
    required this.sourceId,
    required this.payload,
    required this.occurredAt,
    this.actorUserId,
  });

  final String id;
  final String type;
  final String circleId;
  final int? actorUserId;
  final String? sourceType;
  final String? sourceId;
  final Map<String, Object?> payload;
  final DateTime occurredAt;

  factory ActivityItem.fromJson(Map<String, Object?> json) {
    final source = _stringMap(json['source']);
    return ActivityItem(
      id: _requiredString(json, 'id'),
      type: _requiredString(json, 'type'),
      circleId: _requiredString(json, 'circle_id'),
      actorUserId: _nullableInt(json['actor_user_id']),
      sourceType: _nullableString(source?['type']),
      sourceId: _nullableString(source?['id']),
      payload: Map<String, Object?>.unmodifiable(
        _stringMap(json['payload']) ?? const <String, Object?>{},
      ),
      occurredAt: _requiredDateTime(json, 'occurred_at'),
    );
  }

  ActivityKind get kind => ActivityKind.fromApiValue(type);

  String get primaryText {
    return switch (kind) {
      ActivityKind.momentPublished => 'A new Moment was shared',
      ActivityKind.memberJoined => 'A member joined the Circle',
      ActivityKind.memberLeft => 'A member left the Circle',
      ActivityKind.sosActivated => 'SOS was activated',
      ActivityKind.sosEscalated => 'SOS was escalated',
      ActivityKind.sosResolved => 'SOS was resolved',
      ActivityKind.other => 'Circle activity',
    };
  }

  String? get secondaryText {
    if (kind == ActivityKind.momentPublished) {
      final mediaType = _nullableString(payload['media_type']);
      if (mediaType != null) {
        return '${mediaType[0].toUpperCase()}${mediaType.substring(1)} Moment';
      }
    }
    return null;
  }
}

enum ActivityKind {
  momentPublished,
  memberJoined,
  memberLeft,
  sosActivated,
  sosEscalated,
  sosResolved,
  other;

  static ActivityKind fromApiValue(String value) {
    return switch (value) {
      'moment.published' => ActivityKind.momentPublished,
      'member.joined' => ActivityKind.memberJoined,
      'member.left' => ActivityKind.memberLeft,
      'alert.sos_activated' => ActivityKind.sosActivated,
      'alert.sos_escalated' => ActivityKind.sosEscalated,
      'alert.sos_resolved' => ActivityKind.sosResolved,
      _ => ActivityKind.other,
    };
  }
}

enum ActivityReportReason {
  spam('spam', 'Spam'),
  harassment('harassment', 'Harassment'),
  safety('safety', 'Safety concern'),
  other('other', 'Other');

  const ActivityReportReason(this.apiValue, this.label);

  final String apiValue;
  final String label;
}

class ActivityFeedPage {
  const ActivityFeedPage({
    required this.items,
    required this.hasMore,
    this.nextCursor,
  });

  final List<ActivityItem> items;
  final String? nextCursor;
  final bool hasMore;

  factory ActivityFeedPage.fromEnvelope(Map<String, Object?> envelope) {
    final data = envelope['data'];
    if (data is! List) {
      throw const FormatException('Activity feed data is not a list.');
    }
    final meta = _stringMap(envelope['meta']) ?? const <String, Object?>{};
    return ActivityFeedPage(
      items: List<ActivityItem>.unmodifiable(
        data.map((item) => ActivityItem.fromJson(_requiredMap(item))),
      ),
      nextCursor: _nullableString(meta['next_cursor']),
      hasMore: meta['has_more'] == true,
    );
  }
}

Map<String, Object?> _requiredMap(Object? value) {
  final map = _stringMap(value);
  if (map == null) {
    throw const FormatException('Expected a JSON object.');
  }
  return map;
}

Map<String, Object?>? _stringMap(Object? value) {
  if (value is! Map) {
    return null;
  }
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _requiredString(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! String || value.trim().isEmpty) {
    throw FormatException('Missing or invalid $key.');
  }
  return value.trim();
}

String? _nullableString(Object? value) {
  return value is String && value.trim().isNotEmpty ? value.trim() : null;
}

int? _nullableInt(Object? value) {
  if (value is int) {
    return value;
  }
  return value is num ? value.toInt() : null;
}

DateTime _requiredDateTime(Map<String, Object?> data, String key) {
  final value = _nullableString(data[key]);
  final parsed = value == null ? null : DateTime.tryParse(value);
  if (parsed == null) {
    throw FormatException('Missing or invalid $key.');
  }
  return parsed.toLocal();
}
