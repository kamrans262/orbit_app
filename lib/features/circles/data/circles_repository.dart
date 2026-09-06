import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../domain/orbit_circle.dart';

abstract interface class CirclesRepository {
  Future<List<OrbitCircle>> listCircles();
  Future<OrbitCircle> getCircle(String circleId);
  Future<OrbitCircle> createCircle(CreateCircleInput input);
  Future<OrbitCircle> joinCircle(String code);
  Future<OrbitCircle> updateCircle({
    required String circleId,
    required String name,
    String? description,
  });
  Future<void> archiveCircle(String circleId);
  Future<OrbitCircleInvite> createInvite({
    required String circleId,
    required CreateCircleInviteInput input,
  });
  Future<List<OrbitCircleMember>> listMembers(String circleId);
  Future<OrbitCircleMember> updateMemberRole({
    required String circleId,
    required String membershipId,
    required CircleRole role,
  });
  Future<void> removeMember({
    required String circleId,
    required String membershipId,
  });
  Future<void> leaveCircle(String circleId);
}

class HttpCirclesRepository implements CirclesRepository {
  HttpCirclesRepository({required OrbitApiClient apiClient})
    : this._(apiClient);

  HttpCirclesRepository._(this._api);

  final OrbitApiClient _api;

  @override
  Future<List<OrbitCircle>> listCircles() async {
    final data = await _api.getDataList('v1/circles');
    return data
        .map((item) => _parseCircle(_stringMap(item)))
        .toList(growable: false);
  }

  @override
  Future<OrbitCircle> getCircle(String circleId) async {
    final data = await _api.getDataMap('v1/circles/$circleId');
    return _parseCircle(data.cast<String, Object?>());
  }

  @override
  Future<OrbitCircle> createCircle(CreateCircleInput input) async {
    final payload = <String, Object?>{
      'name': input.name.trim(),
      'type': input.type.apiValue,
    };
    final description = input.description?.trim();
    if (description != null && description.isNotEmpty) {
      payload['description'] = description;
    }
    if (input.type == CircleType.temporary && input.expiresAt != null) {
      payload['expires_at'] = input.expiresAt!.toUtc().toIso8601String();
    }

    final data = await _api.postDataMap('v1/circles', data: payload);
    return _parseCircle(data.cast<String, Object?>());
  }

  @override
  Future<OrbitCircle> joinCircle(String code) async {
    final data = await _api.postDataMap(
      'v1/circles/join',
      data: <String, Object?>{'code': code.trim().toUpperCase()},
    );
    return _parseCircle(data.cast<String, Object?>());
  }

  @override
  Future<OrbitCircle> updateCircle({
    required String circleId,
    required String name,
    String? description,
  }) async {
    final data = await _api.patchDataMap(
      'v1/circles/$circleId',
      data: <String, Object?>{
        'name': name.trim(),
        'description': description?.trim().isEmpty == true
            ? null
            : description?.trim(),
      },
    );
    return _parseCircle(data.cast<String, Object?>());
  }

  @override
  Future<void> archiveCircle(String circleId) {
    return _api.delete('v1/circles/$circleId');
  }

  @override
  Future<OrbitCircleInvite> createInvite({
    required String circleId,
    required CreateCircleInviteInput input,
  }) async {
    final data = await _api.postDataMap(
      'v1/circles/$circleId/invites',
      data: <String, Object?>{
        'expires_in_minutes': input.expiresInMinutes,
        'max_uses': input.maxUses,
      },
    );
    return _parseInvite(data.cast<String, Object?>());
  }

  @override
  Future<List<OrbitCircleMember>> listMembers(String circleId) async {
    final data = await _api.getDataList('v1/circles/$circleId/members');
    return data
        .map((item) => _parseMember(_stringMap(item)))
        .toList(growable: false);
  }

  @override
  Future<OrbitCircleMember> updateMemberRole({
    required String circleId,
    required String membershipId,
    required CircleRole role,
  }) async {
    final data = await _api.patchDataMap(
      'v1/circles/$circleId/members/$membershipId',
      data: <String, Object?>{'role': role.apiValue},
    );
    return _parseMember(data.cast<String, Object?>());
  }

  @override
  Future<void> removeMember({
    required String circleId,
    required String membershipId,
  }) {
    return _api.delete('v1/circles/$circleId/members/$membershipId');
  }

  @override
  Future<void> leaveCircle(String circleId) async {
    await _api.postDataMap('v1/circles/$circleId/leave');
  }

  static OrbitCircle _parseCircle(Map<String, Object?> data) {
    return OrbitCircle(
      id: _requiredString(data, 'id'),
      name: _requiredString(data, 'name'),
      description: _nullableString(data['description']),
      type: CircleType.parse(data['type']),
      myRole: CircleRole.parse(data['my_role']),
      myMembershipId: _requiredString(data, 'my_membership_id'),
      memberCount: _intOrZero(data['member_count']),
      expiresAt: _dateOrNull(data['expires_at']),
      isArchived: data['is_archived'] == true,
      isExpired: data['is_expired'] == true,
      createdAt: _dateOrNull(data['created_at']),
      updatedAt: _dateOrNull(data['updated_at']),
    );
  }

  static OrbitCircleMember _parseMember(Map<String, Object?> data) {
    final user = _stringMap(data['user']);
    return OrbitCircleMember(
      membershipId: _requiredString(data, 'membership_id'),
      role: CircleRole.parse(data['role']),
      locationMode: _requiredString(data, 'location_mode'),
      canPing: data['can_ping'] == true,
      canMessage: data['can_message'] == true,
      canViewMoments: data['can_view_moments'] == true,
      activityVisibility: data['activity_visibility'] == true,
      joinedAt: _dateOrNull(data['joined_at']),
      userId: _requiredInt(user, 'id'),
      name: _nullableString(user['name']) ?? 'Orbit member',
      email: _requiredString(user, 'email'),
    );
  }

  static OrbitCircleInvite _parseInvite(Map<String, Object?> data) {
    final expiresAt = _dateOrNull(data['expires_at']);
    if (expiresAt == null) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected Circle invite response.',
      );
    }
    return OrbitCircleInvite(
      id: _requiredString(data, 'id'),
      code: _requiredString(data, 'code'),
      maxUses: _requiredInt(data, 'max_uses'),
      usesCount: _requiredInt(data, 'uses_count'),
      expiresAt: expiresAt,
    );
  }

  static Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected Circle response.',
      );
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static String _requiredString(Map<String, Object?> data, String key) {
    final value = data[key];
    if (value is! String || value.trim().isEmpty) {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected Circle response.',
      );
    }
    return value.trim();
  }

  static int _requiredInt(Map<String, Object?> data, String key) {
    final value = data[key];
    return switch (value) {
      int number => number,
      num number => number.toInt(),
      String text when int.tryParse(text) != null => int.parse(text),
      _ => throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected Circle response.',
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

  static DateTime? _dateOrNull(Object? value) {
    return value is String ? DateTime.tryParse(value)?.toLocal() : null;
  }
}
