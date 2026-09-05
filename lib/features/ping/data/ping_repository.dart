import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../domain/ping_item.dart';

abstract interface class PingRepository {
  Future<List<PingItem>> listInbox();

  Future<List<PingItem>> listSent();

  Future<List<PingCircleOption>> listCircles();

  Future<List<PingTarget>> listTargets(PingCircleOption circle);

  Future<PingItem> send({
    required String circleId,
    required String recipientMembershipId,
  });

  Future<PingItem> respond(String pingId, PingResponseType responseType);

  Future<PingItem> dismiss(String pingId);
}

class HttpPingRepository implements PingRepository {
  HttpPingRepository({required OrbitApiClient apiClient}) : this._(apiClient);

  HttpPingRepository._(this._api);

  final OrbitApiClient _api;

  @override
  Future<List<PingItem>> listInbox() async {
    return _parsePings(await _api.getDataList('v1/pings/inbox'));
  }

  @override
  Future<List<PingItem>> listSent() async {
    return _parsePings(await _api.getDataList('v1/pings/sent'));
  }

  @override
  Future<List<PingCircleOption>> listCircles() async {
    final data = await _api.getDataList('v1/circles');
    return data
        .map((item) {
          final circle = _stringMap(item);
          return PingCircleOption(
            id: _requiredString(circle, 'id'),
            name: _requiredString(circle, 'name'),
            myMembershipId: _requiredString(circle, 'my_membership_id'),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<PingTarget>> listTargets(PingCircleOption circle) async {
    final data = await _api.getDataList('v1/circles/${circle.id}/members');
    final targets = <PingTarget>[];

    for (final item in data) {
      final member = _stringMap(item);
      final membershipId = _requiredString(member, 'membership_id');
      if (membershipId == circle.myMembershipId) {
        continue;
      }
      final user = _stringMap(member['user']);
      targets.add(
        PingTarget(
          membershipId: membershipId,
          name:
              _nullableString(user['name']) ??
              _nullableString(user['email']) ??
              'Orbit member',
          canPing: member['can_ping'] == true,
        ),
      );
    }

    return List<PingTarget>.unmodifiable(targets);
  }

  @override
  Future<PingItem> send({
    required String circleId,
    required String recipientMembershipId,
  }) async {
    final data = await _api.postDataMap(
      'v1/pings',
      data: <String, Object?>{
        'circle_id': circleId,
        'recipient_membership_id': recipientMembershipId,
      },
    );
    return PingItem.fromJson(data.cast<String, Object?>());
  }

  @override
  Future<PingItem> respond(String pingId, PingResponseType responseType) async {
    final data = await _api.postDataMap(
      'v1/pings/$pingId/respond',
      data: <String, Object?>{'response_type': responseType.apiValue},
    );
    return PingItem.fromJson(data.cast<String, Object?>());
  }

  @override
  Future<PingItem> dismiss(String pingId) async {
    final data = await _api.postDataMap('v1/pings/$pingId/dismiss');
    return PingItem.fromJson(data.cast<String, Object?>());
  }

  static List<PingItem> _parsePings(List<dynamic> data) {
    return data
        .map((item) {
          final map = _stringMap(item);
          try {
            return PingItem.fromJson(map);
          } on FormatException {
            throw const OrbitApiException(
              code: 'INVALID_RESPONSE',
              message: 'Orbit returned an unexpected Ping response.',
            );
          }
        })
        .toList(growable: false);
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

  static String? _nullableString(Object? value) {
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }
}
