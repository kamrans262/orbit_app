import 'package:flutter_test/flutter_test.dart';
import 'package:orbit_app/core/network/orbit_api_client.dart';
import 'package:orbit_app/core/network/orbit_binary_transfer_client.dart';
import 'package:orbit_app/features/media/data/media_remote_repository.dart';
import 'package:orbit_app/features/media/domain/media_models.dart';

void main() {
  test(
    'creates upload with ciphertext-only metadata and no automatic replay',
    () async {
      final api = _FakeApiClient()
        ..mapResponse = <String, dynamic>{
          'upload_id': 'upload-id',
          'asset_id': 'asset-id',
          'chunk_size_bytes': 262144,
          'total_chunks': 2,
          'expires_at': '2026-09-06T12:00:00Z',
        };
      final repository = HttpMediaRemoteRepository(
        apiClient: api,
        binaryClient: _FakeBinaryClient(),
      );

      await repository.createUpload(
        circleId: 'circle-id',
        assetId: 'asset-id',
        uploaderDeviceId: 'device-id',
        kind: OrbitMediaKind.image,
        contentTypeHint: 'image/jpeg',
        sizeBytes: 42,
        sha256Ciphertext: ''.padLeft(64, 'a'),
      );

      expect(api.lastPath, 'v1/circles/circle-id/media/uploads');
      expect(api.lastData?['uploader_device_id'], 'device-id');
      expect(api.lastData?['kind'], 'image');
      expect(api.lastData?.containsKey('filename'), isFalse);
      expect(api.lastData?.containsKey('caption'), isFalse);
      expect(api.lastAllowRetry, isFalse);
    },
  );

  test('uploads raw encrypted chunk with its sha256 header', () async {
    final binary = _FakeBinaryClient();
    final repository = HttpMediaRemoteRepository(
      apiClient: _FakeApiClient(),
      binaryClient: binary,
    );

    await repository.uploadChunk(
      uploadId: 'upload-id',
      chunkIndex: 3,
      bytes: const <int>[1, 2, 3, 4],
    );

    expect(binary.lastPath, 'v1/media/uploads/upload-id/chunks/3');
    expect(binary.lastHeaders?['X-Chunk-SHA256'], hasLength(64));
    expect(binary.lastAllowRetry, isTrue);
  });

  test(
    'completion can replay because Laravel completion is idempotent',
    () async {
      final api = _FakeApiClient()
        ..mapResponse = <String, dynamic>{
          'asset_id': 'asset-id',
          'circle_id': 'circle-id',
          'kind': 'image',
          'content_type_hint': 'image/jpeg',
          'size_bytes': 42,
          'sha256_ciphertext': ''.padLeft(64, 'b'),
        };
      final repository = HttpMediaRemoteRepository(
        apiClient: api,
        binaryClient: _FakeBinaryClient(),
      );

      await repository.completeUpload(
        uploadId: 'upload-id',
        keyEnvelopes: const <OutboundMediaKeyEnvelope>[
          OutboundMediaKeyEnvelope(
            recipientDeviceId: 'device-id',
            algorithm: 'algorithm',
            encryptedKey: 'ciphertext',
          ),
        ],
      );

      expect(api.lastPath, 'v1/media/uploads/upload-id/complete');
      expect(api.lastAllowRetry, isTrue);
    },
  );

  test(
    'asset deletion never automatically replays after auth refresh',
    () async {
      final api = _FakeApiClient();
      final repository = HttpMediaRemoteRepository(
        apiClient: api,
        binaryClient: _FakeBinaryClient(),
      );

      await repository.deleteAsset('asset-id');

      expect(api.lastPath, 'v1/media/asset-id');
      expect(api.lastAllowRetry, isFalse);
    },
  );

  test('rejects invalid ciphertext hash metadata returned by server', () {
    expect(
      () => OrbitMediaAsset.fromJson(<String, Object?>{
        'asset_id': 'asset-id',
        'circle_id': 'circle-id',
        'kind': 'image',
        'size_bytes': 42,
        'sha256_ciphertext': 'not-a-sha256',
      }),
      throwsFormatException,
    );
  });
}

class _FakeBinaryClient implements OrbitBinaryTransferClient {
  String? lastPath;
  Map<String, String>? lastHeaders;
  bool? lastAllowRetry;

  @override
  Future<void> putBytes(
    String path,
    List<int> bytes, {
    Map<String, String>? headers,
    bool allowAuthRetry = false,
  }) async {
    lastPath = path;
    lastHeaders = headers;
    lastAllowRetry = allowAuthRetry;
  }

  @override
  Future<void> downloadToFile(
    String path,
    String destinationPath, {
    Map<String, Object?>? queryParameters,
  }) async {}
}

class _FakeApiClient implements OrbitApiClient {
  String? lastPath;
  Map<String, Object?>? lastData;
  bool? lastAllowRetry;
  Map<String, dynamic> mapResponse = <String, dynamic>{};

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
  }) async => <dynamic>[];

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
