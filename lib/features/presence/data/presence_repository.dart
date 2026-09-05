import '../../../core/location/current_location_reader.dart';
import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../../../core/security/session_store.dart';
import '../domain/presence_snapshot.dart';

abstract interface class PresenceRepository {
  Future<PresenceSnapshot> getMyPresence();

  Future<PresenceSnapshot> shareCurrentLocation();

  Future<PresenceSnapshot> setGlobalGhostMode(bool enabled);

  Future<List<CirclePrivacySetting>> listCirclePrivacy();

  Future<CirclePrivacySetting> updateCirclePrivacy({
    required CirclePrivacySetting current,
    PresenceLocationMode? locationMode,
    bool? canPing,
  });
}

class HttpPresenceRepository implements PresenceRepository {
  HttpPresenceRepository({
    required OrbitApiClient apiClient,
    required SessionStore sessionStore,
    required CurrentLocationReader locationReader,
  }) : this._(apiClient, sessionStore, locationReader);

  HttpPresenceRepository._(this._api, this._sessionStore, this._locationReader);

  final OrbitApiClient _api;
  final SessionStore _sessionStore;
  final CurrentLocationReader _locationReader;

  @override
  Future<PresenceSnapshot> getMyPresence() async {
    final data = await _api.getDataMap('v1/presence/me');
    return PresenceSnapshot.fromJson(data.cast<String, Object?>());
  }

  @override
  Future<PresenceSnapshot> shareCurrentLocation() async {
    final session = await _sessionStore.read();
    if (session == null) {
      throw const OrbitApiException(
        code: 'UNAUTHENTICATED',
        message: 'Sign in again before sharing your presence.',
        statusCode: 401,
      );
    }

    final current = await getMyPresence();
    if (current.globalGhostMode) {
      throw const OrbitApiException(
        code: 'GLOBAL_GHOST_MODE_ENABLED',
        message: 'Turn off Global Ghost Mode before sharing location.',
        statusCode: 409,
      );
    }

    final location = await _locationReader.read();
    final data = await _api.putDataMap(
      'v1/presence',
      data: <String, Object?>{
        'device_id': session.deviceId,
        'status': 'online',
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy_meters': location.accuracyMeters,
      },
      allowAuthRetry: true,
    );

    return PresenceSnapshot.fromJson(data.cast<String, Object?>());
  }

  @override
  Future<PresenceSnapshot> setGlobalGhostMode(bool enabled) async {
    final data = await _api.patchDataMap(
      'v1/presence/settings',
      data: <String, Object?>{'global_ghost_mode': enabled},
      allowAuthRetry: true,
    );
    return PresenceSnapshot.fromJson(data.cast<String, Object?>());
  }

  @override
  Future<List<CirclePrivacySetting>> listCirclePrivacy() async {
    final circles = await _api.getDataList('v1/circles');
    final settings = <CirclePrivacySetting>[];

    for (final item in circles) {
      final circle = _stringMap(item);
      final circleId = _requiredString(circle, 'id');
      final circleName = _requiredString(circle, 'name');
      final membershipId = _requiredString(circle, 'my_membership_id');
      final members = await _api.getDataList('v1/circles/$circleId/members');

      Map<String, Object?>? mine;
      for (final rawMember in members) {
        final member = _stringMap(rawMember);
        if (member['membership_id'] == membershipId) {
          mine = member;
          break;
        }
      }

      if (mine == null) {
        continue;
      }

      settings.add(
        CirclePrivacySetting(
          circleId: circleId,
          circleName: circleName,
          membershipId: membershipId,
          locationMode: PresenceLocationMode.parse(mine['location_mode']),
          canPing: mine['can_ping'] == true,
        ),
      );
    }

    return List<CirclePrivacySetting>.unmodifiable(settings);
  }

  @override
  Future<CirclePrivacySetting> updateCirclePrivacy({
    required CirclePrivacySetting current,
    PresenceLocationMode? locationMode,
    bool? canPing,
  }) async {
    final payload = <String, Object?>{};
    if (locationMode != null) {
      payload['location_mode'] = locationMode.apiValue;
    }
    if (canPing != null) {
      payload['can_ping'] = canPing;
    }
    if (payload.isEmpty) {
      return current;
    }

    final data = await _api.patchDataMap(
      'v1/circles/${current.circleId}/members/${current.membershipId}',
      data: payload,
      allowAuthRetry: true,
    );

    return CirclePrivacySetting(
      circleId: current.circleId,
      circleName: current.circleName,
      membershipId: _requiredString(data, 'membership_id'),
      locationMode: PresenceLocationMode.parse(data['location_mode']),
      canPing: data['can_ping'] == true,
    );
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected response.',
      );
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String _requiredString(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected response.',
      );
    }
    return value;
  }
}
