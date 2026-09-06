import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_envelope_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../domain/orbit_notification.dart';

abstract interface class NotificationsRepository {
  Future<NotificationFeed> listNotifications({int limit = 50});

  Future<OrbitNotification> markRead(String notificationId);

  Future<int> markAllRead();

  Future<NotificationPreferences> getPreferences();

  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  );

  Future<void> updateCirclePreference({
    required String circleId,
    DateTime? mutedUntil,
    bool clearMute = false,
    bool? silent,
  });

  Future<List<OrbitAnnouncement>> listAnnouncements();
}

class HttpNotificationsRepository implements NotificationsRepository {
  const HttpNotificationsRepository({
    required OrbitApiClient apiClient,
    required OrbitApiEnvelopeClient envelopeClient,
  }) : _api = apiClient,
       _envelope = envelopeClient;

  final OrbitApiClient _api;
  final OrbitApiEnvelopeClient _envelope;

  @override
  Future<NotificationFeed> listNotifications({int limit = 50}) async {
    final envelope = await _envelope.getEnvelope(
      'v1/notifications',
      queryParameters: <String, Object?>{'limit': limit},
    );
    try {
      return NotificationFeed.fromEnvelope(envelope.cast<String, Object?>());
    } on FormatException {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected notification response.',
      );
    }
  }

  @override
  Future<OrbitNotification> markRead(String notificationId) async {
    final data = await _api.postDataMap(
      'v1/notifications/${Uri.encodeComponent(notificationId)}/read',
      allowAuthRetry: true,
    );
    try {
      return OrbitNotification.fromJson(data.cast<String, Object?>());
    } on FormatException {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected notification response.',
      );
    }
  }

  @override
  Future<int> markAllRead() async {
    final data = await _api.postDataMap(
      'v1/notifications/read-all',
      allowAuthRetry: true,
    );
    final updated = data['updated'];
    if (updated is int) {
      return updated;
    }
    if (updated is num) {
      return updated.toInt();
    }
    throw const OrbitApiException(
      code: 'INVALID_RESPONSE',
      message: 'Orbit returned an unexpected notification response.',
    );
  }

  @override
  Future<NotificationPreferences> getPreferences() async {
    final data = await _api.getDataMap('v1/notifications/preferences');
    return _parsePreferences(data);
  }

  @override
  Future<NotificationPreferences> updatePreferences(
    NotificationPreferences preferences,
  ) async {
    final data = await _api.putDataMap(
      'v1/notifications/preferences',
      data: preferences.toApiPayload(),
      allowAuthRetry: true,
    );
    return _parsePreferences(data);
  }

  @override
  Future<void> updateCirclePreference({
    required String circleId,
    DateTime? mutedUntil,
    bool clearMute = false,
    bool? silent,
  }) async {
    await _api.putDataMap(
      'v1/notifications/circles/${Uri.encodeComponent(circleId)}',
      data: <String, Object?>{
        if (mutedUntil != null || clearMute)
          'muted_until': mutedUntil?.toUtc().toIso8601String(),
        'silent': ?silent,
      },
      allowAuthRetry: true,
    );
  }

  @override
  Future<List<OrbitAnnouncement>> listAnnouncements() async {
    final data = await _api.getDataList('v1/communications/announcements');
    try {
      return List<OrbitAnnouncement>.unmodifiable(
        data.map((item) => OrbitAnnouncement.fromJson(_stringMap(item))),
      );
    } on FormatException {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected announcement response.',
      );
    }
  }

  static NotificationPreferences _parsePreferences(Map<String, dynamic> data) {
    try {
      return NotificationPreferences.fromJson(data.cast<String, Object?>());
    } on FormatException {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned unexpected notification preferences.',
      );
    }
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('Expected JSON object.');
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
