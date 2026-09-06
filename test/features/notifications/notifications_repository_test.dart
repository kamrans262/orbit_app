import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/network/orbit_api_client.dart';
import 'package:orbit_app/core/network/orbit_api_envelope_client.dart';
import 'package:orbit_app/features/notifications/data/notifications_repository.dart';

void main() {
  test(
    'parses notification inbox meta and derives only supported internal routes',
    () async {
      final transport = _NotificationsTransportFake();
      transport.envelopeResponse = <String, dynamic>{
        'data': <Object?>[
          <String, Object?>{
            'id': 'notification-1',
            'kind': 'message.received',
            'priority': 'normal',
            'summary': 'New message',
            'circle_id': 'circle-1',
            'payload': <String, Object?>{
              'message_id': 'message-1',
              'encrypted_preview': 'ciphertext-only',
            },
            'deep_link': 'orbit://circles/circle-1/messages',
            'read_at': null,
            'created_at': '2026-09-06T09:00:00Z',
          },
        ],
        'meta': <String, Object?>{'limit': 50, 'unread_count': 7},
      };
      final repository = HttpNotificationsRepository(
        apiClient: transport,
        envelopeClient: transport,
      );

      final feed = await repository.listNotifications();

      expect(feed.unreadCount, 7);
      expect(feed.items, hasLength(1));
      expect(feed.items.single.summary, 'New message');
      expect(feed.items.single.internalRoute, '/circles/circle-1/messages');
      expect(feed.items.single.payload, isNot(contains('plaintext')));
      expect(transport.lastEnvelopePath, 'v1/notifications');
    },
  );

  test(
    'marks notifications read and preserves server preference contract',
    () async {
      final transport = _NotificationsTransportFake();
      transport.postResponses['v1/notifications/notification-1/read'] =
          <String, dynamic>{
            'id': 'notification-1',
            'kind': 'ping.received',
            'priority': 'high',
            'summary': 'New Ping',
            'circle_id': 'circle-1',
            'payload': <String, Object?>{'ping_id': 'ping-1'},
            'deep_link': null,
            'read_at': '2026-09-06T09:01:00Z',
            'created_at': '2026-09-06T09:00:00Z',
          };
      transport.postResponses['v1/notifications/read-all'] = <String, dynamic>{
        'updated': 3,
      };
      transport.getMapResponses['v1/notifications/preferences'] =
          _preferenceJson(pushEnabled: true);
      transport.putResponses['v1/notifications/preferences'] = _preferenceJson(
        pushEnabled: false,
      );

      final repository = HttpNotificationsRepository(
        apiClient: transport,
        envelopeClient: transport,
      );

      final read = await repository.markRead('notification-1');
      final updatedCount = await repository.markAllRead();
      final preferences = await repository.getPreferences();
      final saved = await repository.updatePreferences(
        preferences.copyWith(pushEnabled: false),
      );

      expect(read.isRead, isTrue);
      expect(read.internalRoute, '/pings');
      expect(updatedCount, 3);
      expect(preferences.pushEnabled, isTrue);
      expect(saved.pushEnabled, isFalse);
      expect(transport.lastPutAllowAuthRetry, isTrue);
      expect(transport.lastPutData, containsPair('quiet_hours_enabled', false));
    },
  );

  test('loads only backend-published consumer announcement fields', () async {
    final transport = _NotificationsTransportFake();
    transport.listResponses['v1/communications/announcements'] = <dynamic>[
      <String, Object?>{
        'id': 'announcement-1',
        'type': 'security',
        'priority': 100,
        'dismissible': false,
        'deep_link': null,
        'title': 'Security update',
        'body': 'Review this important Orbit security notice.',
        'starts_at': '2026-09-06T00:00:00Z',
        'ends_at': null,
      },
    ];
    final repository = HttpNotificationsRepository(
      apiClient: transport,
      envelopeClient: transport,
    );

    final announcements = await repository.listAnnouncements();

    expect(announcements, hasLength(1));
    expect(announcements.single.title, 'Security update');
    expect(announcements.single.dismissible, isFalse);
  });
}

Map<String, dynamic> _preferenceJson({required bool pushEnabled}) {
  return <String, dynamic>{
    'push_enabled': pushEnabled,
    'in_app_enabled': true,
    'messages_enabled': true,
    'moments_enabled': true,
    'pings_enabled': true,
    'activity_enabled': true,
    'quiet_hours_enabled': false,
    'quiet_hours_start': null,
    'quiet_hours_end': null,
    'timezone': 'Asia/Karachi',
  };
}

class _NotificationsTransportFake
    implements OrbitApiClient, OrbitApiEnvelopeClient {
  Map<String, dynamic> envelopeResponse = <String, dynamic>{
    'data': <Object?>[],
    'meta': <String, Object?>{'limit': 50, 'unread_count': 0},
  };
  final Map<String, Map<String, dynamic>> getMapResponses =
      <String, Map<String, dynamic>>{};
  final Map<String, List<dynamic>> listResponses = <String, List<dynamic>>{};
  final Map<String, Map<String, dynamic>> postResponses =
      <String, Map<String, dynamic>>{};
  final Map<String, Map<String, dynamic>> putResponses =
      <String, Map<String, dynamic>>{};

  String? lastEnvelopePath;
  Object? lastPutData;
  bool? lastPutAllowAuthRetry;

  @override
  Future<Map<String, dynamic>> getEnvelope(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    lastEnvelopePath = path;
    return envelopeResponse;
  }

  @override
  Future<Map<String, dynamic>> getDataMap(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    return getMapResponses[path] ?? <String, dynamic>{};
  }

  @override
  Future<List<dynamic>> getDataList(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    return listResponses[path] ?? <dynamic>[];
  }

  @override
  Future<Map<String, dynamic>> postDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    return postResponses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> putDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    lastPutData = data;
    lastPutAllowAuthRetry = allowAuthRetry;
    return putResponses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> patchDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) => throw UnimplementedError();

  @override
  Future<void> delete(
    String path, {
    bool authenticated = true,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) => throw UnimplementedError();

  @override
  Future<bool> refreshIdentitySession() async => false;

  @override
  void close() {}
}
