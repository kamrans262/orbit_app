import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../../presence/domain/presence_snapshot.dart';
import '../domain/home_overview.dart';

abstract interface class HomeOverviewRepository {
  Future<List<HomeCircleSummary>> listCircles();

  Future<List<HomePresenceMember>> listCirclePresence(String circleId);
}

class ApiHomeOverviewRepository implements HomeOverviewRepository {
  ApiHomeOverviewRepository({required OrbitApiClient apiClient})
    : this._(apiClient);

  ApiHomeOverviewRepository._(this._api);

  final OrbitApiClient _api;

  @override
  Future<List<HomeCircleSummary>> listCircles() async {
    final data = await _api.getDataList('v1/circles');
    return data
        .map((item) {
          final circle = _stringMap(item);
          return HomeCircleSummary(
            id: _requiredString(circle, 'id'),
            name: _requiredString(circle, 'name'),
            memberCount: _intOrZero(circle['member_count']),
            myMembershipId: _requiredString(circle, 'my_membership_id'),
          );
        })
        .toList(growable: false);
  }

  @override
  Future<List<HomePresenceMember>> listCirclePresence(String circleId) async {
    final data = await _api.getDataList('v1/circles/$circleId/presence');
    return data
        .map((item) {
          final member = _stringMap(item);
          final user = _stringMap(member['user']);
          final presence = _stringMap(member['presence']);
          final location = _stringMap(presence['location']);

          return HomePresenceMember(
            membershipId: _requiredString(member, 'membership_id'),
            userId: _requiredInt(user, 'id'),
            name: _nullableString(user['name']) ?? 'Orbit member',
            status: PresenceStatus.parse(presence['status']),
            locationMode: PresenceLocationMode.parse(location['mode']),
          );
        })
        .toList(growable: false);
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected Home response.',
      );
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String _requiredString(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected Home response.',
      );
    }
    return value;
  }

  static int _requiredInt(Map<String, Object?> data, String key) {
    final value = data[key];
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String text when int.tryParse(text) != null => int.parse(text),
      _ => throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected Home response.',
      ),
    };
  }

  static int _intOrZero(Object? value) {
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String text => int.tryParse(text) ?? 0,
      _ => 0,
    };
  }

  static String? _nullableString(Object? value) {
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }
}
