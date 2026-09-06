import '../../../core/network/orbit_api_client.dart';
import '../../../core/network/orbit_api_exception.dart';
import '../domain/orbit_profile.dart';

abstract interface class ProfileRepository {
  Future<OrbitProfile> loadProfile();

  Future<OrbitProfile> updateProfile({
    String? name,
    required String timezone,
    required String locale,
  });
}

class HttpProfileRepository implements ProfileRepository {
  const HttpProfileRepository({required OrbitApiClient apiClient})
    : _api = apiClient;

  final OrbitApiClient _api;

  @override
  Future<OrbitProfile> loadProfile() async {
    final data = await _api.getDataMap('v1/profile');
    return _parse(data);
  }

  @override
  Future<OrbitProfile> updateProfile({
    String? name,
    required String timezone,
    required String locale,
  }) async {
    final cleanName = name?.trim();
    final data = await _api.patchDataMap(
      'v1/profile',
      data: <String, Object?>{
        'name': cleanName == null || cleanName.isEmpty ? null : cleanName,
        'timezone': timezone.trim(),
        'locale': locale.trim(),
      },
      allowAuthRetry: true,
    );
    return _parse(data);
  }

  static OrbitProfile _parse(Map<String, dynamic> data) {
    try {
      return OrbitProfile.fromJson(data.cast<String, Object?>());
    } on FormatException {
      throw const OrbitApiException(
        code: 'INVALID_RESPONSE',
        message: 'Orbit returned an unexpected profile response.',
      );
    }
  }
}
