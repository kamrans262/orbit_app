import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/network/orbit_api_client.dart';
import 'package:orbit_app/core/network/orbit_api_command_client.dart';
import 'package:orbit_app/core/network/orbit_api_envelope_client.dart';
import 'package:orbit_app/features/activity/data/activity_repository.dart';
import 'package:orbit_app/features/activity/domain/activity_item.dart';

void main() {
  test('parses the backend Activity envelope and cursor metadata', () async {
    final transport = _ActivityTransportFake(
      envelope: <String, dynamic>{
        'data': <Object?>[
          <String, Object?>{
            'id': 'activity-1',
            'type': 'moment.published',
            'circle_id': 'circle-1',
            'actor_user_id': 7,
            'source': <String, Object?>{'type': 'moment', 'id': 'moment-1'},
            'payload': <String, Object?>{
              'moment_id': 'moment-1',
              'media_type': 'image',
            },
            'occurred_at': '2026-09-06T08:00:00Z',
          },
        ],
        'meta': <String, Object?>{
          'next_cursor': 'cursor-2',
          'has_more': true,
          'per_page': 20,
        },
      },
    );
    final repository = HttpActivityRepository(
      apiClient: transport,
      envelopeClient: transport,
      commandClient: transport,
    );

    final page = await repository.listFeed(limit: 20);

    expect(page.items, hasLength(1));
    expect(page.items.single.kind, ActivityKind.momentPublished);
    expect(page.nextCursor, 'cursor-2');
    expect(page.hasMore, isTrue);
    expect(transport.lastEnvelopePath, 'v1/activity/feed');
    expect(transport.lastEnvelopeQuery?['limit'], 20);
  });

  test('uses idempotent server Activity hide and report contracts', () async {
    final transport = _ActivityTransportFake(
      envelope: <String, dynamic>{
        'data': <Object?>[],
        'meta': <String, Object?>{},
      },
    );
    final repository = HttpActivityRepository(
      apiClient: transport,
      envelopeClient: transport,
      commandClient: transport,
    );

    await repository.hide('activity 1');
    await repository.report(
      activityId: 'activity 1',
      reason: ActivityReportReason.safety,
      details: 'Please review.',
    );

    expect(transport.lastCommandPath, 'v1/activity/activity%201/hide');
    expect(transport.lastCommandAllowAuthRetry, isTrue);
    expect(transport.lastPostPath, 'v1/activity/activity%201/report');
    expect(transport.lastPostAllowAuthRetry, isTrue);
    expect(transport.lastPostData, <String, Object?>{
      'reason': 'safety',
      'details': 'Please review.',
    });
  });
}

class _ActivityTransportFake
    implements OrbitApiClient, OrbitApiEnvelopeClient, OrbitApiCommandClient {
  _ActivityTransportFake({required this.envelope});

  final Map<String, dynamic> envelope;
  String? lastEnvelopePath;
  Map<String, Object?>? lastEnvelopeQuery;
  String? lastCommandPath;
  bool? lastCommandAllowAuthRetry;
  String? lastPostPath;
  Object? lastPostData;
  bool? lastPostAllowAuthRetry;

  @override
  Future<Map<String, dynamic>> getEnvelope(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    lastEnvelopePath = path;
    lastEnvelopeQuery = queryParameters;
    return envelope;
  }

  @override
  Future<void> postNoContent(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    lastCommandPath = path;
    lastCommandAllowAuthRetry = allowAuthRetry;
  }

  @override
  Future<Map<String, dynamic>> postDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    lastPostPath = path;
    lastPostData = data;
    lastPostAllowAuthRetry = allowAuthRetry;
    return <String, dynamic>{
      'id': 'report-1',
      'activity_id': 'activity-1',
      'status': 'pending',
    };
  }

  @override
  Future<Map<String, dynamic>> getDataMap(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) => throw UnimplementedError();

  @override
  Future<List<dynamic>> getDataList(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) => throw UnimplementedError();

  @override
  Future<Map<String, dynamic>> putDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) => throw UnimplementedError();

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
