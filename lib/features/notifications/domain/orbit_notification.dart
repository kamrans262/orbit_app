class OrbitNotification {
  const OrbitNotification({
    required this.id,
    required this.kind,
    required this.priority,
    required this.summary,
    required this.payload,
    required this.createdAt,
    this.circleId,
    this.deepLink,
    this.readAt,
  });

  final String id;
  final String kind;
  final String priority;
  final String summary;
  final String? circleId;
  final Map<String, Object?> payload;
  final String? deepLink;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isRead => readAt != null;
  bool get isHighestPriority => priority == 'highest';
  bool get isHighPriority => priority == 'high' || isHighestPriority;

  String? get internalRoute {
    if (kind.startsWith('sos.')) {
      final id = _nullableString(payload['sos_id']);
      return id == null ? null : '/sos/${Uri.encodeComponent(id)}';
    }

    switch (kind) {
      case 'ping.received':
        return '/pings';
      case 'message.received':
        final id = circleId ?? _nullableString(payload['circle_id']);
        return id == null
            ? null
            : '/circles/${Uri.encodeComponent(id)}/messages';
      case 'moment.published':
        final id = _nullableString(payload['moment_id']);
        return id == null ? null : '/moments/${Uri.encodeComponent(id)}';
      default:
        return null;
    }
  }

  factory OrbitNotification.fromJson(Map<String, Object?> json) {
    return OrbitNotification(
      id: _requiredString(json, 'id'),
      kind: _requiredString(json, 'kind'),
      priority: _requiredString(json, 'priority'),
      summary: _requiredString(json, 'summary'),
      circleId: _nullableString(json['circle_id']),
      payload: Map<String, Object?>.unmodifiable(
        _stringMap(json['payload']) ?? const <String, Object?>{},
      ),
      deepLink: _nullableString(json['deep_link']),
      readAt: _nullableDateTime(json['read_at']),
      createdAt: _requiredDateTime(json, 'created_at'),
    );
  }
}

class NotificationFeed {
  const NotificationFeed({
    required this.items,
    required this.unreadCount,
    required this.limit,
  });

  final List<OrbitNotification> items;
  final int unreadCount;
  final int limit;

  factory NotificationFeed.fromEnvelope(Map<String, Object?> envelope) {
    final data = envelope['data'];
    if (data is! List) {
      throw const FormatException('Notification feed data is not a list.');
    }
    final meta = _stringMap(envelope['meta']) ?? const <String, Object?>{};
    return NotificationFeed(
      items: List<OrbitNotification>.unmodifiable(
        data.map((item) => OrbitNotification.fromJson(_requiredMap(item))),
      ),
      unreadCount: _intValue(meta['unread_count']) ?? 0,
      limit: _intValue(meta['limit']) ?? data.length,
    );
  }
}

class NotificationPreferences {
  const NotificationPreferences({
    required this.pushEnabled,
    required this.inAppEnabled,
    required this.messagesEnabled,
    required this.momentsEnabled,
    required this.pingsEnabled,
    required this.activityEnabled,
    required this.quietHoursEnabled,
    required this.timezone,
    this.quietHoursStart,
    this.quietHoursEnd,
  });

  final bool pushEnabled;
  final bool inAppEnabled;
  final bool messagesEnabled;
  final bool momentsEnabled;
  final bool pingsEnabled;
  final bool activityEnabled;
  final bool quietHoursEnabled;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final String timezone;

  factory NotificationPreferences.fromJson(Map<String, Object?> json) {
    return NotificationPreferences(
      pushEnabled: _requiredBool(json, 'push_enabled'),
      inAppEnabled: _requiredBool(json, 'in_app_enabled'),
      messagesEnabled: _requiredBool(json, 'messages_enabled'),
      momentsEnabled: _requiredBool(json, 'moments_enabled'),
      pingsEnabled: _requiredBool(json, 'pings_enabled'),
      activityEnabled: _requiredBool(json, 'activity_enabled'),
      quietHoursEnabled: _requiredBool(json, 'quiet_hours_enabled'),
      quietHoursStart: _nullableString(json['quiet_hours_start']),
      quietHoursEnd: _nullableString(json['quiet_hours_end']),
      timezone: _nullableString(json['timezone']) ?? 'UTC',
    );
  }

  Map<String, Object?> toApiPayload() {
    return <String, Object?>{
      'push_enabled': pushEnabled,
      'in_app_enabled': inAppEnabled,
      'messages_enabled': messagesEnabled,
      'moments_enabled': momentsEnabled,
      'pings_enabled': pingsEnabled,
      'activity_enabled': activityEnabled,
      'quiet_hours_enabled': quietHoursEnabled,
      'quiet_hours_start': quietHoursStart,
      'quiet_hours_end': quietHoursEnd,
      'timezone': timezone,
    };
  }

  NotificationPreferences copyWith({
    bool? pushEnabled,
    bool? inAppEnabled,
    bool? messagesEnabled,
    bool? momentsEnabled,
    bool? pingsEnabled,
    bool? activityEnabled,
    bool? quietHoursEnabled,
    String? quietHoursStart,
    bool clearQuietHoursStart = false,
    String? quietHoursEnd,
    bool clearQuietHoursEnd = false,
    String? timezone,
  }) {
    return NotificationPreferences(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      messagesEnabled: messagesEnabled ?? this.messagesEnabled,
      momentsEnabled: momentsEnabled ?? this.momentsEnabled,
      pingsEnabled: pingsEnabled ?? this.pingsEnabled,
      activityEnabled: activityEnabled ?? this.activityEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietHoursStart: clearQuietHoursStart
          ? null
          : quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: clearQuietHoursEnd
          ? null
          : quietHoursEnd ?? this.quietHoursEnd,
      timezone: timezone ?? this.timezone,
    );
  }
}

class OrbitAnnouncement {
  const OrbitAnnouncement({
    required this.id,
    required this.type,
    required this.priority,
    required this.dismissible,
    required this.title,
    required this.body,
    this.deepLink,
    this.startsAt,
    this.endsAt,
  });

  final String id;
  final String type;
  final int priority;
  final bool dismissible;
  final String title;
  final String body;
  final String? deepLink;
  final DateTime? startsAt;
  final DateTime? endsAt;

  factory OrbitAnnouncement.fromJson(Map<String, Object?> json) {
    return OrbitAnnouncement(
      id: _requiredString(json, 'id'),
      type: _requiredString(json, 'type'),
      priority: _intValue(json['priority']) ?? 0,
      dismissible: json['dismissible'] == true,
      deepLink: _nullableString(json['deep_link']),
      title: _nullableString(json['title']) ?? 'Orbit update',
      body: _nullableString(json['body']) ?? '',
      startsAt: _nullableDateTime(json['starts_at']),
      endsAt: _nullableDateTime(json['ends_at']),
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
  final value = _nullableString(data[key]);
  if (value == null) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

String? _nullableString(Object? value) {
  return value is String && value.trim().isNotEmpty ? value.trim() : null;
}

DateTime _requiredDateTime(Map<String, Object?> data, String key) {
  final value = _nullableDateTime(data[key]);
  if (value == null) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}

DateTime? _nullableDateTime(Object? value) {
  if (value is! String || value.trim().isEmpty) {
    return null;
  }
  return DateTime.tryParse(value)?.toLocal();
}

int? _intValue(Object? value) {
  if (value is int) {
    return value;
  }
  return value is num ? value.toInt() : null;
}

bool _requiredBool(Map<String, Object?> data, String key) {
  final value = data[key];
  if (value is! bool) {
    throw FormatException('Missing or invalid $key.');
  }
  return value;
}
