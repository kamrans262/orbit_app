import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/network/orbit_api_client.dart';
import 'package:orbit_app/features/moments/data/moments_repository.dart';

void main() {
  test('publish uses backend idempotent moment_id contract', () async {
    final api = _FakeApiClient()..mapResponse = _momentJson();
    final repository = HttpMomentsRepository(apiClient: api);

    await repository.publishMoment(
      circleId: 'circle-id',
      momentId: 'moment-id',
      mediaAssetId: 'asset-id',
    );

    expect(api.lastPath, 'v1/circles/circle-id/moments');
    expect(api.lastData?['moment_id'], 'moment-id');
    expect(api.lastData?['media_asset_id'], 'asset-id');
    expect(api.lastAllowRetry, isTrue);
  });

  test('view receipt uses canonical Moment view endpoint', () async {
    final api = _FakeApiClient()
      ..mapResponse = <String, dynamic>{'recorded': true, 'anonymous': false};
    final repository = HttpMomentsRepository(apiClient: api);

    final result = await repository.recordView('moment-id');

    expect(result.recorded, isTrue);
    expect(api.lastPath, 'v1/moments/moment-id/view');
  });

  test(
    'Moment deletion is destructive and is never automatically replayed',
    () async {
      final api = _FakeApiClient();
      final repository = HttpMomentsRepository(apiClient: api);

      await repository.deleteMoment('moment-id');

      expect(api.lastPath, 'v1/moments/moment-id');
      expect(api.lastAllowRetry, isFalse);
    },
  );
}

Map<String, dynamic> _momentJson() => <String, dynamic>{
  'id': 'moment-id',
  'circle_id': 'circle-id',
  'author': <String, Object?>{'user_id': 1, 'name': 'Owner'},
  'media': <String, Object?>{
    'asset_id': 'asset-id',
    'kind': 'image',
    'content_type_hint': 'image/jpeg',
    'size_bytes': 100,
    'sha256_ciphertext': ''.padLeft(64, 'a'),
  },
  'view_count': 0,
  'is_mine': true,
  'expires_at': '2026-09-07T00:00:00Z',
  'created_at': '2026-09-06T00:00:00Z',
};

class _FakeApiClient implements OrbitApiClient {
  String? lastPath;
  Map<String, Object?>? lastData;
  bool? lastAllowRetry;
  Map<String, dynamic> mapResponse = <String, dynamic>{};
  List<dynamic> listResponse = <dynamic>[];

  @override
  Future<Map<String, dynamic>> getDataMap(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    lastPath = path;
    return mapResponse;
  }

  @override
  Future<List<dynamic>> getDataList(
    String path, {
    bool authenticated = true,
    Map<String, Object?>? queryParameters,
    String? bearerToken,
  }) async {
    lastPath = path;
    return listResponse;
  }

  @override
  Future<Map<String, dynamic>> postDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    lastPath = path;
    lastData = data is Map<String, Object?> ? data : null;
    lastAllowRetry = allowAuthRetry;
    return mapResponse;
  }

  @override
  Future<Map<String, dynamic>> putDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async => <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> patchDataMap(
    String path, {
    bool authenticated = true,
    Object? data,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async => <String, dynamic>{};

  @override
  Future<void> delete(
    String path, {
    bool authenticated = true,
    bool allowAuthRetry = false,
    String? bearerToken,
  }) async {
    lastPath = path;
    lastAllowRetry = allowAuthRetry;
  }

  @override
  Future<bool> refreshIdentitySession() async => true;

  @override
  void close() {}
}
