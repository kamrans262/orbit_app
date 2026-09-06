import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_command_client.dart';
import '../../../core/network/orbit_api_envelope_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../domain/activity_item.dart';

abstract interface class ActivityRepository {
  Future<ActivityFeedPage> listFeed({int limit = 20, String? cursor});

  Future<void> hide(String activityId);

  Future<void> report({
    required String activityId,
    required ActivityReportReason reason,
    String? details,
  });
}

class HttpActivityRepository implements ActivityRepository {
  const HttpActivityRepository({
    required OrbitApiClient apiClient,
    required OrbitApiEnvelopeClient envelopeClient,
    required OrbitApiCommandClient commandClient,
  }) : _api = apiClient,
       _envelope = envelopeClient,
       _commands = commandClient;

  final OrbitApiClient _api;
  final OrbitApiEnvelopeClient _envelope;
  final OrbitApiCommandClient _commands;

  @override
  Future<ActivityFeedPage> listFeed({int limit = 20, String? cursor}) async {
    final envelope = await _envelope.getEnvelope(
      'v1/activity/feed',
      queryParameters: <String, Object?>{
        'limit': limit,
        if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
      },
    );

    try {
      return ActivityFeedPage.fromEnvelope(envelope.cast<String, Object?>());
    } on FormatException {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected Activity response.',
      );
    }
  }

  @override
  Future<void> hide(String activityId) {
    return _commands.postNoContent(
      'v1/activity/${Uri.encodeComponent(activityId)}/hide',
      allowAuthRetry: true,
    );
  }

  @override
  Future<void> report({
    required String activityId,
    required ActivityReportReason reason,
    String? details,
  }) async {
    await _api.postDataMap(
      'v1/activity/${Uri.encodeComponent(activityId)}/report',
      data: <String, Object?>{
        'reason': reason.apiValue,
        if (details != null && details.trim().isNotEmpty)
          'details': details.trim(),
      },
      allowAuthRetry: true,
    );
  }
}
