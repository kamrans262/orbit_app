import '../../../core/network/orbit_api_client.dart';
import '../domain/moment_models.dart';

abstract interface class MomentsRepository {
  Future<List<OrbitMoment>> listCircleMoments(String circleId);
  Future<OrbitMoment> getMoment(String momentId);
  Future<OrbitMoment> publishMoment({
    required String circleId,
    required String momentId,
    required String mediaAssetId,
    int? ttlSeconds,
  });
  Future<MomentViewResult> recordView(String momentId);
  Future<MomentViewers> listViewers(String momentId);
  Future<void> deleteMoment(String momentId);
}

class HttpMomentsRepository implements MomentsRepository {
  HttpMomentsRepository({required OrbitApiClient apiClient})
    : this._(apiClient);

  HttpMomentsRepository._(this._apiClient);

  final OrbitApiClient _apiClient;

  @override
  Future<List<OrbitMoment>> listCircleMoments(String circleId) async {
    final data = await _apiClient.getDataList('v1/circles/$circleId/moments');
    return data
        .map((item) => OrbitMoment.fromJson(_stringMap(item)))
        .toList(growable: false);
  }

  @override
  Future<OrbitMoment> getMoment(String momentId) async {
    return OrbitMoment.fromJson(
      _stringMap(await _apiClient.getDataMap('v1/moments/$momentId')),
    );
  }

  @override
  Future<OrbitMoment> publishMoment({
    required String circleId,
    required String momentId,
    required String mediaAssetId,
    int? ttlSeconds,
  }) async {
    final payload = <String, Object?>{
      'moment_id': momentId,
      'media_asset_id': mediaAssetId,
    };
    if (ttlSeconds != null) {
      payload['ttl_seconds'] = ttlSeconds;
    }

    return OrbitMoment.fromJson(
      _stringMap(
        await _apiClient.postDataMap(
          'v1/circles/$circleId/moments',
          data: payload,
          // moment_id is the backend idempotency key.
          allowAuthRetry: true,
        ),
      ),
    );
  }

  @override
  Future<MomentViewResult> recordView(String momentId) async {
    return MomentViewResult.fromJson(
      _stringMap(
        await _apiClient.postDataMap(
          'v1/moments/$momentId/view',
          allowAuthRetry: true,
        ),
      ),
    );
  }

  @override
  Future<MomentViewers> listViewers(String momentId) async {
    return MomentViewers.fromJson(
      _stringMap(await _apiClient.getDataMap('v1/moments/$momentId/viewers')),
    );
  }

  @override
  Future<void> deleteMoment(String momentId) {
    return _apiClient.delete(
      'v1/moments/$momentId',
      // Deleting the same Moment twice returns not-found, so do not replay a
      // destructive request automatically after authentication refresh.
      allowAuthRetry: false,
    );
  }

  Map<String, Object?> _stringMap(Object? value) {
    if (value is! Map) {
      throw const FormatException('Invalid Orbit Moment response.');
    }
    return value.map((key, item) => MapEntry(key.toString(), item));
  }
}
